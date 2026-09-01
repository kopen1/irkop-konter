-- Compatibility for older IRKOP Cell clients that still select category_id.
-- V2 uses the existing text `category` field, but keeping this nullable column
-- prevents older deployed clients from failing while data is migrated.
alter table public.irkop_cell_products
  add column if not exists category_id uuid;

create index if not exists irkop_cell_products_category_id_idx
  on public.irkop_cell_products(category_id);
