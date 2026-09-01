alter table if exists public.irkop_cell_products
  add column if not exists barcode text;

alter table if exists public.irkop_cell_products
  add column if not exists reorder_level numeric not null default 0;

create index if not exists idx_products_barcode
  on public.irkop_cell_products(business_id, barcode);

create index if not exists idx_products_low_stock
  on public.irkop_cell_products(business_id, stock, reorder_level);
