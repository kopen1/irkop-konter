-- Product schema compatibility + demo seed support.
-- Safe to run on existing IRKOP Cell databases.

create table if not exists public.irkop_cell_product_categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  name text not null,
  track_stock boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(business_id, name)
);

alter table public.irkop_cell_products
  add column if not exists category_id uuid references public.irkop_cell_product_categories(id) on delete set null,
  add column if not exists unit text not null default 'pcs',
  add column if not exists cost_price numeric(14,2) not null default 0,
  add column if not exists min_stock numeric(14,2) not null default 0,
  add column if not exists updated_at timestamptz not null default now();

alter table public.irkop_cell_businesses
  add column if not exists is_demo boolean not null default false;

create index if not exists irkop_cell_products_business_category_idx
  on public.irkop_cell_products(business_id, category_id);
create index if not exists irkop_cell_products_business_sku_idx
  on public.irkop_cell_products(business_id, sku);

alter table public.irkop_cell_product_categories enable row level security;
drop policy if exists "owners manage product categories" on public.irkop_cell_product_categories;
create policy "owners manage product categories"
on public.irkop_cell_product_categories for all to authenticated
using (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()))
with check (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));

-- Keep the product table accessible to the same tenant owner model.
drop policy if exists "owners manage products" on public.irkop_cell_products;
create policy "owners manage products"
on public.irkop_cell_products for all to authenticated
using (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()))
with check (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));

-- Idempotent updated_at trigger for categories.
create or replace function public.irkop_cell_touch_category_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists irkop_cell_product_categories_touch_updated_at on public.irkop_cell_product_categories;
create trigger irkop_cell_product_categories_touch_updated_at before update on public.irkop_cell_product_categories for each row execute function public.irkop_cell_touch_category_updated_at();
