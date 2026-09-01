alter table if exists public.irkop_cell_expenses
  add column if not exists category text;

alter table if exists public.irkop_cell_expenses
  add column if not exists notes text;

alter table if exists public.irkop_cell_expenses
  add column if not exists status text not null default 'approved';

alter table if exists public.irkop_cell_payroll_records
  add column if not exists status text not null default 'draft';

alter table if exists public.irkop_cell_payroll_records
  add column if not exists paid_amount numeric not null default 0;

alter table if exists public.irkop_cell_services
  add column if not exists status text not null default 'pending';

alter table if exists public.irkop_cell_services
  add column if not exists notes text;

alter table if exists public.irkop_cell_services
  add column if not exists customer_id uuid;

create index if not exists idx_services_status
  on public.irkop_cell_services(business_id, status);

create index if not exists idx_expenses_category
  on public.irkop_cell_expenses(business_id, category);
