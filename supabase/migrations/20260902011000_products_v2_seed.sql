insert into public.irkop_cell_products
(
  business_id,
  name,
  sku,
  category,
  selling_price,
  purchase_price,
  stock,
  is_active,
  unit,
  min_stock,
  cost_price
)
select
  b.id,
  'Produk Demo',
  'DEMO-001',
  'Umum',
  10000,
  7000,
  10,
  true,
  'pcs',
  2,
  7000
from public.irkop_cell_businesses b
where not exists (
  select 1
  from public.irkop_cell_products p
  where p.business_id = b.id
);
