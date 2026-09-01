-- Product catalog compatibility for existing IRKOP Cell databases.
-- Safe/idempotent: repairs category/unit columns expected by V2.

create table if not exists public.irkop_cell_product_categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  name text not null,
  track_stock boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(business_id,name)
);

alter table public.irkop_cell_products
  add column if not exists category_id uuid,
  add column if not exists unit text not null default 'pcs';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'irkop_cell_products_category_id_fkey'
      and conrelid = 'public.irkop_cell_products'::regclass
  ) then
    alter table public.irkop_cell_products
      add constraint irkop_cell_products_category_id_fkey
      foreign key (category_id)
      references public.irkop_cell_product_categories(id)
      on delete set null;
  end if;
end $$;

create index if not exists irkop_cell_products_business_category_idx
  on public.irkop_cell_products(business_id,category_id);

alter table public.irkop_cell_product_categories enable row level security;
drop policy if exists "owners manage product categories" on public.irkop_cell_product_categories;
create policy "owners manage product categories"
on public.irkop_cell_product_categories
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
));

create or replace function public.irkop_cell_touch_updated_at() returns trigger
language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists irkop_cell_product_categories_touch_updated_at on public.irkop_cell_product_categories;
create trigger irkop_cell_product_categories_touch_updated_at
before update on public.irkop_cell_product_categories
for each row execute function public.irkop_cell_touch_updated_at();

do $$
declare
  r record;
  cid uuid;
begin
  for r in
    select distinct business_id, coalesce(nullif(trim(category),''),'Lainnya') as category_name
    from public.irkop_cell_products
    where business_id is not null
  loop
    insert into public.irkop_cell_product_categories(business_id,name,track_stock,is_active)
    values(r.business_id,r.category_name,true,true)
    on conflict (business_id,name) do update set is_active=true
    returning id into cid;

    update public.irkop_cell_products
    set category_id=cid,
        unit=coalesce(nullif(trim(unit),''),'pcs')
    where business_id=r.business_id
      and coalesce(nullif(trim(category),''),'Lainnya')=r.category_name
      and category_id is null;
  end loop;
end $$;
