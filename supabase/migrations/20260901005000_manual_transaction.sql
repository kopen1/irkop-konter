create or replace function public.irkop_cell_manual_transaction(p_business_id uuid,p_outlet_id uuid,p_total numeric,p_payment_method text,p_transaction_at timestamptz,p_notes text default null)
returns table(id uuid, transaction_no text, payment_method text, status text, total numeric, transaction_at timestamptz)
language plpgsql security definer set search_path=public as $$
declare v_id uuid; v_no text; v_status text;
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 if not exists(select 1 from public.irkop_cell_businesses b where b.id=p_business_id and b.owner_user_id=auth.uid()) then raise exception 'Business access denied'; end if;
 if not exists(select 1 from public.irkop_cell_outlets o where o.id=p_outlet_id and o.business_id=p_business_id and coalesce(o.is_active,true)) then raise exception 'Outlet is not active'; end if;
 if p_total<=0 then raise exception 'Total must be greater than zero'; end if;
 if p_transaction_at < now() - interval '30 days' or p_transaction_at > now() + interval '1 day' then raise exception 'Transaction date must be within the allowed period'; end if;
 if p_payment_method not in ('cash','cash_tunai','transfer','credit') then raise exception 'Invalid payment method'; end if;
 if p_payment_method='credit' then raise exception 'Manual credit transaction requires customer and item detail'; end if;
 v_no:='MAN-'||extract(epoch from clock_timestamp())::bigint::text;
 v_status:=case when p_payment_method='transfer' then 'pending' else 'completed' end;
 insert into public.irkop_cell_transactions(business_id,outlet_id,transaction_no,payment_method,status,total,paid_amount,notes,transaction_at)
 values(p_business_id,p_outlet_id,v_no,p_payment_method,v_status,p_total,case when v_status='completed' then p_total else null end,p_notes,p_transaction_at) returning id into v_id;
 if p_payment_method in ('cash','cash_tunai') then insert into public.irkop_cell_cash_mutations(business_id,outlet_id,transaction_id,mutation_type,amount,description) values(p_business_id,p_outlet_id,v_id,'in',p_total,'Transaksi manual '||v_no); end if;
 insert into public.irkop_cell_audit_logs(business_id,actor_user_id,entity_type,entity_id,action,metadata) values(p_business_id,auth.uid(),'transaction',v_id,'manual_entry',jsonb_build_object('total',p_total,'payment_method',p_payment_method,'transaction_at',p_transaction_at));
 return query select t.id,t.transaction_no,t.payment_method,t.status,t.total,t.transaction_at from public.irkop_cell_transactions t where t.id=v_id;
end $$;
revoke all on function public.irkop_cell_manual_transaction(uuid,uuid,numeric,text,timestamptz,text) from public;
grant execute on function public.irkop_cell_manual_transaction(uuid,uuid,numeric,text,timestamptz,text) to authenticated;
