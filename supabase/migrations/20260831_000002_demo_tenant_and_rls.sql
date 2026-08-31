-- IRKOP Konter: logical DEMO tenant inside the existing Supabase project.
-- No Supabase preview branch or second database is required.

alter table public.irkop_cell_businesses
  add column if not exists is_demo boolean not null default false;

create index if not exists irkop_cell_businesses_owner_idx
  on public.irkop_cell_businesses(owner_user_id);

create index if not exists irkop_cell_outlets_business_idx
  on public.irkop_cell_outlets(business_id);

create index if not exists irkop_cell_products_business_idx
  on public.irkop_cell_products(business_id);

create index if not exists irkop_cell_customers_business_idx
  on public.irkop_cell_customers(business_id);

create index if not exists irkop_cell_transactions_business_at_idx
  on public.irkop_cell_transactions(business_id, transaction_at desc);

-- Owner-scoped policies for every tenant child table.
drop policy if exists "owner reads own outlets" on public.irkop_cell_outlets;
create policy "owner reads own outlets" on public.irkop_cell_outlets
for select to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner writes own outlets" on public.irkop_cell_outlets;
create policy "owner writes own outlets" on public.irkop_cell_outlets
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner manages own products" on public.irkop_cell_products;
create policy "owner manages own products" on public.irkop_cell_products
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner manages own customers" on public.irkop_cell_customers;
create policy "owner manages own customers" on public.irkop_cell_customers
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner manages own transactions" on public.irkop_cell_transactions;
create policy "owner manages own transactions" on public.irkop_cell_transactions
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner reads own transaction items" on public.irkop_cell_transaction_items;
create policy "owner reads own transaction items" on public.irkop_cell_transaction_items
for select to authenticated
using (exists (
  select 1
  from public.irkop_cell_transactions t
  join public.irkop_cell_businesses b on b.id = t.business_id
  where t.id = transaction_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner writes own transaction items" on public.irkop_cell_transaction_items;
create policy "owner writes own transaction items" on public.irkop_cell_transaction_items
for all to authenticated
using (exists (
  select 1
  from public.irkop_cell_transactions t
  join public.irkop_cell_businesses b on b.id = t.business_id
  where t.id = transaction_id and b.owner_user_id = auth.uid()
))
with check (exists (
  select 1
  from public.irkop_cell_transactions t
  join public.irkop_cell_businesses b on b.id = t.business_id
  where t.id = transaction_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner manages own cash mutations" on public.irkop_cell_cash_mutations;
create policy "owner manages own cash mutations" on public.irkop_cell_cash_mutations
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
));

drop policy if exists "owner manages own device slots" on public.irkop_cell_device_slots;
create policy "owner manages own device slots" on public.irkop_cell_device_slots
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id = business_id and b.owner_user_id = auth.uid()
));

-- Public demo reads are intentionally limited to rows belonging to is_demo=true businesses.
drop policy if exists "public reads demo businesses" on public.irkop_cell_businesses;
create policy "public reads demo businesses" on public.irkop_cell_businesses
for select to anon
using (is_demo = true);

drop policy if exists "public reads demo outlets" on public.irkop_cell_outlets;
create policy "public reads demo outlets" on public.irkop_cell_outlets
for select to anon
using (exists (select 1 from public.irkop_cell_businesses b where b.id = business_id and b.is_demo = true));

drop policy if exists "public reads demo products" on public.irkop_cell_products;
create policy "public reads demo products" on public.irkop_cell_products
for select to anon
using (exists (select 1 from public.irkop_cell_businesses b where b.id = business_id and b.is_demo = true));

drop policy if exists "public reads demo customers" on public.irkop_cell_customers;
create policy "public reads demo customers" on public.irkop_cell_customers
for select to anon
using (exists (select 1 from public.irkop_cell_businesses b where b.id = business_id and b.is_demo = true));

drop policy if exists "public reads demo transactions" on public.irkop_cell_transactions;
create policy "public reads demo transactions" on public.irkop_cell_transactions
for select to anon
using (exists (select 1 from public.irkop_cell_businesses b where b.id = business_id and b.is_demo = true));

drop policy if exists "public reads demo transaction items" on public.irkop_cell_transaction_items;
create policy "public reads demo transaction items" on public.irkop_cell_transaction_items
for select to anon
using (exists (
  select 1
  from public.irkop_cell_transactions t
  join public.irkop_cell_businesses b on b.id = t.business_id
  where t.id = transaction_id and b.is_demo = true
));
