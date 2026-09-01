-- v2 financial integrity: atomic checkout, stock movement, audit and credit settlement.
create or replace function public.irkop_cell_checkout(
  p_business_id uuid,
  p_outlet_id uuid,
  p_items jsonb,
  p_payment_method text,
  p_customer_id uuid default null,
  p_transaction_no text default null,
  p_notes text default null
) returns table(id uuid, transaction_no text, payment_method text, status text, total numeric, transaction_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare
  v_total numeric(14,2):=0; v_id uuid; v_no text; v_status text;
  v_item jsonb; v_product record; v_qty numeric(14,2); v_subtotal numeric(14,2);
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_payment_method not in ('cash','transfer','credit','cash_tunai') then raise exception 'Invalid payment method'; end if;
  if not exists(select 1 from irkop_cell_businesses b where b.id=p_business_id and b.owner_user_id=auth.uid()) then raise exception 'Business access denied'; end if;
  if not exists(select 1 from irkop_cell_outlets o where o.id=p_outlet_id and o.business_id=p_business_id and coalesce(o.is_active,true)) then raise exception 'Outlet is not active'; end if;
  if jsonb_typeof(p_items)!='array' or jsonb_array_length(p_items)=0 then raise exception 'Cart is empty'; end if;
  if p_payment_method='credit' and p_customer_id is null then raise exception 'Customer is required for credit'; end if;
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty:=coalesce((v_item->>'qty')::numeric,0);
    if v_qty<=0 then raise exception 'Invalid quantity'; end if;
    select id,name,sell_price,stock into v_product from irkop_cell_products
      where id=(v_item->>'product_id')::uuid and business_id=p_business_id and is_active for update;
    if not found then raise exception 'Product not found'; end if;
    if v_product.stock<v_qty then raise exception 'Insufficient stock for %',v_product.name; end if;
    v_subtotal:=v_qty*v_product.sell_price; v_total:=v_total+v_subtotal;
  end loop;
  v_no:=coalesce(nullif(trim(p_transaction_no),''),'TRX-'||extract(epoch from clock_timestamp())::bigint::text);
  v_status:=case when p_payment_method='transfer' then 'pending' else 'completed' end;
  insert into irkop_cell_transactions(business_id,outlet_id,customer_id,transaction_no,payment_method,status,total,paid_amount,notes)
  values(p_business_id,p_outlet_id,p_customer_id,v_no,p_payment_method,v_status,v_total,case when v_status='completed' then v_total else null end,p_notes)
  returning irkop_cell_transactions.id into v_id;
  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty:=(v_item->>'qty')::numeric;
    select id,name,sell_price,stock into v_product from irkop_cell_products where id=(v_item->>'product_id')::uuid for update;
    v_subtotal:=v_qty*v_product.sell_price;
    insert into irkop_cell_transaction_items(transaction_id,product_id,product_name,qty,unit_price,subtotal)
      values(v_id,v_product.id,v_product.name,v_qty,v_product.sell_price,v_subtotal);
    update irkop_cell_products set stock=stock-v_qty where id=v_product.id;
    insert into irkop_cell_product_stock_movements(business_id,product_id,transaction_id,movement_type,qty,stock_before,stock_after,notes)
      values(p_business_id,v_product.id,v_id,'sale',-v_qty,v_product.stock,v_product.stock-v_qty,'Checkout '+v_no);
  end loop;
  if p_payment_method in ('cash','cash_tunai') then
    insert into irkop_cell_cash_mutations(business_id,outlet_id,transaction_id,mutation_type,amount,description)
      values(p_business_id,p_outlet_id,v_id,'in',v_total,'Penjualan '+v_no);
  end if;
  insert into irkop_cell_audit_logs(business_id,actor_user_id,entity_type,entity_id,action,metadata)
    values(p_business_id,auth.uid(),'transaction',v_id,'checkout',jsonb_build_object('payment_method',p_payment_method,'total',v_total));
  return query select t.id,t.transaction_no,t.payment_method,t.status,t.total,t.transaction_at from irkop_cell_transactions t where t.id=v_id;
end $$;
revoke all on function public.irkop_cell_checkout(uuid,uuid,jsonb,text,uuid,text,text) from public;
grant execute on function public.irkop_cell_checkout(uuid,uuid,jsonb,text,uuid,text,text) to authenticated;

create or replace function public.irkop_cell_settle_credit_status() returns trigger language plpgsql security definer set search_path=public as $$
declare v_total numeric; v_paid numeric; begin
  select total into v_total from irkop_cell_transactions where id=new.transaction_id and business_id=new.business_id and payment_method='credit' for update;
  if not found then raise exception 'Credit transaction not found'; end if;
  select coalesce(sum(amount),0) into v_paid from irkop_cell_credit_payments where transaction_id=new.transaction_id;
  if v_paid>v_total then raise exception 'Credit payment exceeds balance'; end if;
  update irkop_cell_transactions set status=case when v_paid>=v_total then 'completed' else status end,paid_amount=v_paid where id=new.transaction_id;
  return new;
end $$;
drop trigger if exists irkop_cell_credit_payment_settle on public.irkop_cell_credit_payments;
create trigger irkop_cell_credit_payment_settle after insert or update on public.irkop_cell_credit_payments
for each row execute function public.irkop_cell_settle_credit_status();

create or replace function public.irkop_cell_void_transaction(
  p_transaction_id uuid,p_business_id uuid,p_reason text
) returns void language plpgsql security definer set search_path=public as $$
declare v record; begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if not exists(select 1 from irkop_cell_businesses b where b.id=p_business_id and b.owner_user_id=auth.uid()) then raise exception 'Business access denied'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'Void reason is required'; end if;
  select * into v from irkop_cell_transactions where id=p_transaction_id and business_id=p_business_id and status='completed' for update;
  if not found then raise exception 'Transaction cannot be voided'; end if;
  update irkop_cell_transactions set status='void' where id=v.id;
  update irkop_cell_products p set stock=p.stock+i.qty from irkop_cell_transaction_items i where i.transaction_id=v.id and i.product_id=p.id;
  insert into irkop_cell_product_stock_movements(business_id,product_id,transaction_id,movement_type,qty,notes)
    select p_business_id,i.product_id,v.id,'reversal',i.qty,'Void '+v.transaction_no from irkop_cell_transaction_items i where i.transaction_id=v.id and i.product_id is not null;
  if v.payment_method in ('cash','cash_tunai') then
    insert into irkop_cell_cash_mutations(business_id,outlet_id,transaction_id,mutation_type,amount,description)
    values(p_business_id,v.outlet_id,v.id,'reversal',v.total,'Void '+v.transaction_no);
  end if;
  insert into irkop_cell_transaction_void_audit(transaction_id,business_id,reason) values(v.id,p_business_id,trim(p_reason));
  insert into irkop_cell_audit_logs(business_id,actor_user_id,entity_type,entity_id,action,metadata)
    values(p_business_id,auth.uid(),'transaction',v.id,'void',jsonb_build_object('reason',trim(p_reason)));
end $$;
revoke all on function public.irkop_cell_void_transaction(uuid,uuid,text) from public;
grant execute on function public.irkop_cell_void_transaction(uuid,uuid,text) to authenticated;