-- Copy-paste into Supabase SQL Editor
alter table public.irkop_cell_transactions add column if not exists customer_id uuid references public.irkop_cell_customers(id) on delete set null;
create index if not exists irkop_cell_transactions_customer_idx on public.irkop_cell_transactions(customer_id);
