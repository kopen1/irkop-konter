-- Copy-paste into Supabase SQL Editor
create table if not exists public.irkop_cell_devices (id uuid primary key default gen_random_uuid(), business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade, device_name text not null, device_code text not null, is_active boolean not null default true, last_seen_at timestamptz, created_at timestamptz not null default now(), unique(business_id,device_code));
alter table public.irkop_cell_devices enable row level security;
drop policy if exists "owners manage devices" on public.irkop_cell_devices;
create policy "owners manage devices" on public.irkop_cell_devices for all using (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));


-- Final feature support
alter table public.irkop_cell_outlets add column if not exists is_active boolean not null default true;
create table if not exists public.irkop_cell_transaction_void_audit (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.irkop_cell_transactions(id) on delete cascade,
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);
alter table public.irkop_cell_transaction_void_audit enable row level security;
drop policy if exists "owners manage transaction void audit" on public.irkop_cell_transaction_void_audit;
create policy "owners manage transaction void audit" on public.irkop_cell_transaction_void_audit for all
using (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()))
with check (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));
