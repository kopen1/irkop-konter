-- V2 demo seed for IRKOP Konter.
-- Run in Supabase SQL Editor after the product-catalog compatibility migration.
-- It is repeatable and uses the first authenticated user + first owned business.

do $$
declare
  owner_id uuid;
  b uuid;
  o uuid;
  c uuid;
  p uuid;
  t uuid;
  i int;
  cat text;
  methods text[] := array['cash','transfer','cash_tunai','credit'];
begin
  select id into owner_id from auth.users order by created_at asc limit 1;
  if owner_id is null then
    raise exception 'V2 demo seed requires at least one authenticated user.';
  end if;

  select id into b from public.irkop_cell_businesses
  where owner_user_id = owner_id order by created_at asc limit 1;
  if b is null then
    b := gen_random_uuid();
    insert into public.irkop_cell_businesses(id, owner_user_id, name, is_demo)
    values (b, owner_id, 'IRKOP Konter Demo', true);
  end if;

  select id into o from public.irkop_cell_outlets
  where business_id = b order by created_at asc limit 1;
  if o is null then
    o := gen_random_uuid();
    insert into public.irkop_cell_outlets(id, business_id, name, address)
    values (o, b, 'Outlet Demo Utama', 'Indonesia');
  end if;

  insert into public.irkop_cell_product_categories(business_id,name,track_stock)
  values (b,'Pulsa',false),(b,'Aksesoris',true),(b,'Service',true),(b,'Perdana',true),(b,'Voucher',true)
  on conflict (business_id,name) do nothing;

  -- Add products when the tenant is empty. Includes every column used by V2.
  if not exists (select 1 from public.irkop_cell_products where business_id=b) then
    for i in 1..30 loop
      cat := case when i%5=0 then 'Voucher' when i%3=0 then 'Aksesoris' when i%3=1 then 'Pulsa' else 'Service' end;
      insert into public.irkop_cell_products(
        business_id,name,category,category_id,sku,sell_price,stock,cost_price,min_stock,unit,is_active
      ) values (
        b,'Produk Demo '||i,
        cat,
        (select id from public.irkop_cell_product_categories where business_id=b and name=cat),
        'DEMO-SKU-'||lpad(i::text,4,'0'),
        (25000+i*5000)::numeric(14,2),
        (20+i)::numeric(14,2),
        (15000+i*3000)::numeric(14,2),
        5,
        case when i%4=0 then 'unit' else 'pcs' end,
        true
      );
    end loop;
  end if;

  if not exists (select 1 from public.irkop_cell_customers where business_id=b) then
    for i in 1..20 loop
      insert into public.irkop_cell_customers(business_id,name,phone)
      values (b,'Pelanggan Demo '||i,'0812'||lpad((1000000+i)::text,7,'0'));
    end loop;
  end if;

  if not exists (select 1 from public.irkop_cell_transactions where business_id=b) then
    for i in 1..30 loop
      select id into c from public.irkop_cell_customers where business_id=b order by random() limit 1;
      insert into public.irkop_cell_transactions(
        business_id,outlet_id,customer_id,transaction_no,payment_method,status,total,transaction_at
      ) values (
        b,o,c,'DEMO-'||lpad(i::text,5,'0'),methods[1+floor(random()*4)::int],'completed',
        (50000+i*10000)::numeric(14,2),now()-((30-i)||' hours')::interval
      ) returning id into t;
      select id into p from public.irkop_cell_products where business_id=b order by random() limit 1;
      insert into public.irkop_cell_transaction_items(transaction_id,product_id,product_name,qty,unit_price,subtotal)
      select t,id,name,1,sell_price,sell_price from public.irkop_cell_products where id=p;
      insert into public.irkop_cell_cash_mutations(business_id,outlet_id,transaction_id,mutation_type,amount,description)
      select b,o,t,'in',total,'V2 demo transaction' from public.irkop_cell_transactions where id=t;
    end loop;
  end if;
end $$;
