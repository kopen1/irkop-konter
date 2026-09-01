-- Kompatibilitas Produk V2.
-- Aman dijalankan berulang kali.

alter table if exists public.irkop_cell_products
  add column if not exists unit text not null default 'pcs';

alter table if exists public.irkop_cell_products
  add column if not exists min_stock numeric not null default 0;

alter table if exists public.irkop_cell_products
  add column if not exists cost_price numeric not null default 0;

alter table if exists public.irkop_cell_products
  add column if not exists category_id uuid;

create index if not exists idx_irkop_cell_products_business
  on public.irkop_cell_products(business_id);

create index if not exists idx_irkop_cell_products_sku
  on public.irkop_cell_products(business_id, sku);
