-- Repair authenticated owner bootstrap for Business -> Outlet.
-- This migration is idempotent and restores the INSERT policy required
-- when a newly registered owner creates their first Outlet.

alter table public.irkop_cell_businesses enable row level security;
alter table public.irkop_cell_outlets enable row level security;

drop policy if exists "owner manages own business" on public.irkop_cell_businesses;
create policy "owner manages own business"
on public.irkop_cell_businesses
for all
to authenticated
using (owner_user_id = auth.uid())
with check (owner_user_id = auth.uid());

drop policy if exists "owner reads own outlets" on public.irkop_cell_outlets;
create policy "owner reads own outlets"
on public.irkop_cell_outlets
for select
to authenticated
using (
  exists (
    select 1
    from public.irkop_cell_businesses b
    where b.id = business_id
      and b.owner_user_id = auth.uid()
  )
);

drop policy if exists "owner writes own outlets" on public.irkop_cell_outlets;
create policy "owner writes own outlets"
on public.irkop_cell_outlets
for insert
to authenticated
with check (
  exists (
    select 1
    from public.irkop_cell_businesses b
    where b.id = business_id
      and b.owner_user_id = auth.uid()
  )
);

drop policy if exists "owner updates own outlets" on public.irkop_cell_outlets;
create policy "owner updates own outlets"
on public.irkop_cell_outlets
for update
to authenticated
using (
  exists (
    select 1
    from public.irkop_cell_businesses b
    where b.id = business_id
      and b.owner_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.irkop_cell_businesses b
    where b.id = business_id
      and b.owner_user_id = auth.uid()
  )
);

drop policy if exists "owner deletes own outlets" on public.irkop_cell_outlets;
create policy "owner deletes own outlets"
on public.irkop_cell_outlets
for delete
to authenticated
using (
  exists (
    select 1
    from public.irkop_cell_businesses b
    where b.id = business_id
      and b.owner_user_id = auth.uid()
  )
);
