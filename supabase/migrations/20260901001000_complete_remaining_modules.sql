-- IRKOP Konter: complete parity modules for Service HP and Gaji.
create table if not exists public.irkop_cell_service_orders (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
 order_no text not null, customer_name text not null, customer_phone text, device_name text not null, complaint text not null default '',
 status text not null default 'received' check (status in ('received','process','waiting_parts','ready','completed','cancelled')),
 estimated_cost numeric(14,2) not null default 0 check (estimated_cost>=0), final_cost numeric(14,2), notes text,
 received_at timestamptz not null default now(), completed_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 unique(business_id,order_no));
create table if not exists public.irkop_cell_payroll_records (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
 employee_name text not null, period date not null, base_amount numeric(14,2) not null default 0 check(base_amount>=0),
 bonus_amount numeric(14,2) not null default 0 check(bonus_amount>=0), deduction_amount numeric(14,2) not null default 0 check(deduction_amount>=0),
 paid_at timestamptz, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(base_amount+bonus_amount>=deduction_amount));
create table if not exists public.irkop_cell_money_accounts (
 id uuid primary key default gen_random_uuid(), business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
 name text not null, account_type text not null default 'cash' check(account_type in ('cash','bank','ewallet','other')),
 opening_balance numeric(14,2) not null default 0, is_active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create index if not exists irkop_cell_service_orders_business_status_idx on public.irkop_cell_service_orders(business_id,status,received_at desc);
create index if not exists irkop_cell_payroll_business_period_idx on public.irkop_cell_payroll_records(business_id,period desc);
create index if not exists irkop_cell_money_accounts_business_idx on public.irkop_cell_money_accounts(business_id,is_active);
alter table public.irkop_cell_service_orders enable row level security;
alter table public.irkop_cell_payroll_records enable row level security;
alter table public.irkop_cell_money_accounts enable row level security;
drop policy if exists "owners manage service orders" on public.irkop_cell_service_orders;
create policy "owners manage service orders" on public.irkop_cell_service_orders for all to authenticated using(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));
drop policy if exists "owners manage payroll records" on public.irkop_cell_payroll_records;
create policy "owners manage payroll records" on public.irkop_cell_payroll_records for all to authenticated using(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));
drop policy if exists "owners manage money accounts" on public.irkop_cell_money_accounts;
create policy "owners manage money accounts" on public.irkop_cell_money_accounts for all to authenticated using(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));
drop trigger if exists irkop_cell_service_orders_touch_updated_at on public.irkop_cell_service_orders;
create trigger irkop_cell_service_orders_touch_updated_at before update on public.irkop_cell_service_orders for each row execute function public.irkop_cell_touch_updated_at();
drop trigger if exists irkop_cell_payroll_records_touch_updated_at on public.irkop_cell_payroll_records;
create trigger irkop_cell_payroll_records_touch_updated_at before update on public.irkop_cell_payroll_records for each row execute function public.irkop_cell_touch_updated_at();
drop trigger if exists irkop_cell_money_accounts_touch_updated_at on public.irkop_cell_money_accounts;
create trigger irkop_cell_money_accounts_touch_updated_at before update on public.irkop_cell_money_accounts for each row execute function public.irkop_cell_touch_updated_at();