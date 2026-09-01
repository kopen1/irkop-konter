-- Product catalog parity with IRKOP Cell: category master, product code,
-- cost price, minimum stock and unit. All changes are additive/idempotent.
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
  add column if not exists category_id uuid references public.irkop_cell_product_categories(id) on delete set null,
  add column if not exists cost_price numeric(14,2) not null default 0,
  add column if not exists min_stock numeric(14,2) not null default 0,
  add column if not exists unit text not null default 'pcs';

create unique index if not exists irkop_cell_products_business_sku_uidx
  on public.irkop_cell_products(business_id,sku) where sku is not null and btrim(sku) <> '';
create index if not exists irkop_cell_product_categories_business_idx
  on public.irkop_cell_product_categories(business_id,is_active,name);

alter table public.irkop_cell_product_categories enable row level security;
drop policy if exists "owners manage product categories" on public.irkop_cell_product_categories;
create policy "owners manage product categories" on public.irkop_cell_product_categories
for all to authenticated
using (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()))
with check (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));

drop trigger if exists irkop_cell_product_categories_touch_updated_at on public.irkop_cell_product_categories;
create trigger irkop_cell_product_categories_touch_updated_at
before update on public.irkop_cell_product_categories
for each row execute function public.irkop_cell_touch_updated_at();

alter table public.irkop_cell_products drop constraint if exists irkop_cell_products_cost_nonnegative;
alter table public.irkop_cell_products add constraint irkop_cell_products_cost_nonnegative check (cost_price >= 0);
alter table public.irkop_cell_products drop constraint if exists irkop_cell_products_min_stock_nonnegative;
alter table public.irkop_cell_products add constraint irkop_cell_products_min_stock_nonnegative check (min_stock >= 0);
