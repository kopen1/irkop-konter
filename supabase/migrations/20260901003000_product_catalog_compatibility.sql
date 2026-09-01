-- Product catalog compatibility for existing IRKOP Cell databases.
-- Older databases may not have the V2 category/unit columns.

alter table public.irkop_cell_products
  add column if not exists category_id uuid references public.irkop_cell_product_categories(id) on delete set null,
  add column if not exists unit text not null default 'pcs';

create index if not exists irkop_cell_products_category_idx
  on public.irkop_cell_products(business_id, category_id);

-- Backfill category_id from the legacy category text when possible.
update public.irkop_cell_products p
set category_id = c.id
from public.irkop_cell_product_categories c
where p.business_id = c.business_id
  and p.category_id is null
  and lower(trim(coalesce(p.category, ''))) = lower(trim(c.name));

-- Keep existing rows usable by the V2 catalog.
update public.irkop_cell_products
set unit = 'pcs'
where unit is null or trim(unit) = '';
