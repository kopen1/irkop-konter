-- IRKOP Konter: complete schema alignment for all implemented application modules.
-- Safe for existing databases: all additions are idempotent.

create extension if not exists pgcrypto;

-- OUTLETS
alter table public.irkop_cell_outlets
  add column if not exists is_active boolean not null default true;
create index if not exists irkop_cell_outlets_business_active_idx
  on public.irkop_cell_outlets(business_id, is_active);

-- CUSTOMERS
alter table public.irkop_cell_customers
  add column if not exists email text,
  add column if not exists address text,
  add column if not exists notes text,
  add column if not exists is_active boolean not null default true,
  add column if not exists updated_at timestamptz not null default now();

-- PRODUCTS
alter table public.irkop_cell_products
  add column if not exists cost_price numeric(14,2) not null default 0,
  add column if not exists min_stock numeric(14,2) not null default 0,
  add column if not exists updated_at timestamptz not null default now();

-- TRANSACTIONS
alter table public.irkop_cell_transactions
  add column if not exists customer_id uuid references public.irkop_cell_customers(id) on delete set null,
  add column if not exists discount numeric(14,2) not null default 0,
  add column if not exists paid_amount numeric(14,2),
  add column if not exists due_date date,
  add column if not exists notes text,
  add column if not exists updated_at timestamptz not null default now();

-- The app supports completed/cancelled/pending and void transactions.
alter table public.irkop_cell_transactions
  drop constraint if exists irkop_cell_transactions_status_check;
alter table public.irkop_cell_transactions
  add constraint irkop_cell_transactions_status_check
  check (status in ('pending','completed','cancelled','void'));

create index if not exists irkop_cell_transactions_customer_idx
  on public.irkop_cell_transactions(business_id, customer_id);
create index if not exists irkop_cell_transactions_business_status_at_idx
  on public.irkop_cell_transactions(business_id, status, transaction_at desc);

-- TRANSACTION ITEMS
alter table public.irkop_cell_transaction_items
  add column if not exists created_at timestamptz not null default now();

-- DEVICES
create table if not exists public.irkop_cell_devices (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  device_name text not null,
  device_code text not null,
  is_active boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default now(),
  unique(business_id, device_code)
);
create index if not exists irkop_cell_devices_business_active_idx
  on public.irkop_cell_devices(business_id, is_active);
alter table public.irkop_cell_devices enable row level security;
drop policy if exists "owners manage devices" on public.irkop_cell_devices;
create policy "owners manage devices" on public.irkop_cell_devices
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
));

-- TRANSACTION VOID AUDIT
create table if not exists public.irkop_cell_transaction_void_audit (
  id uuid primary key default gen_random_uuid(),
  transaction_id uuid not null references public.irkop_cell_transactions(id) on delete cascade,
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  reason text not null,
  created_at timestamptz not null default now()
);
create index if not exists irkop_cell_void_audit_transaction_idx
  on public.irkop_cell_transaction_void_audit(transaction_id, created_at desc);
alter table public.irkop_cell_transaction_void_audit enable row level security;
drop policy if exists "owners manage transaction void audit" on public.irkop_cell_transaction_void_audit;
create policy "owners manage transaction void audit"
on public.irkop_cell_transaction_void_audit
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
));

-- CREDIT PAYMENTS
create table if not exists public.irkop_cell_credit_payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  transaction_id uuid not null references public.irkop_cell_transactions(id) on delete cascade,
  customer_id uuid references public.irkop_cell_customers(id) on delete set null,
  amount numeric(14,2) not null check(amount>0),
  paid_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);
create index if not exists irkop_cell_credit_payments_tx_idx
  on public.irkop_cell_credit_payments(business_id, transaction_id, paid_at desc);
alter table public.irkop_cell_credit_payments enable row level security;
drop policy if exists "owner manages own credit payments" on public.irkop_cell_credit_payments;
create policy "owner manages own credit payments" on public.irkop_cell_credit_payments
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
));

-- STOCK MOVEMENTS
create table if not exists public.irkop_cell_product_stock_movements (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  product_id uuid not null references public.irkop_cell_products(id) on delete cascade,
  transaction_id uuid references public.irkop_cell_transactions(id) on delete set null,
  movement_type text not null check(movement_type in ('in','out','adjustment','sale','reversal')),
  qty numeric(14,2) not null,
  stock_before numeric(14,2),
  stock_after numeric(14,2),
  notes text,
  occurred_at timestamptz not null default now()
);
create index if not exists irkop_cell_stock_movements_product_idx
  on public.irkop_cell_product_stock_movements(business_id, product_id, occurred_at desc);
alter table public.irkop_cell_product_stock_movements enable row level security;
drop policy if exists "owner manages own stock movements" on public.irkop_cell_product_stock_movements;
create policy "owner manages own stock movements" on public.irkop_cell_product_stock_movements
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
));

-- AUDIT LOGS
create table if not exists public.irkop_cell_audit_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists irkop_cell_audit_logs_idx
  on public.irkop_cell_audit_logs(business_id, created_at desc);
alter table public.irkop_cell_audit_logs enable row level security;
drop policy if exists "owner manages own audit logs" on public.irkop_cell_audit_logs;
create policy "owner manages own audit logs" on public.irkop_cell_audit_logs
for all to authenticated
using (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
))
with check (exists (
  select 1 from public.irkop_cell_businesses b
  where b.id=business_id and b.owner_user_id=auth.uid()
));

-- REPORTING VIEWS
create or replace view public.irkop_cell_daily_sales as
select
  business_id,
  outlet_id,
  transaction_at::date as sale_date,
  count(*) filter(where status='completed') as transaction_count,
  coalesce(sum(total) filter(where status='completed'),0) as revenue
from public.irkop_cell_transactions
group by business_id,outlet_id,transaction_at::date;

create or replace view public.irkop_cell_credit_balances as
select
  t.id as transaction_id,
  t.business_id,
  t.customer_id,
  t.transaction_no,
  t.total,
  coalesce(sum(p.amount),0) as paid,
  greatest(t.total-coalesce(sum(p.amount),0),0) as balance,
  t.due_date,
  t.status
from public.irkop_cell_transactions t
left join public.irkop_cell_credit_payments p on p.transaction_id=t.id
where t.payment_method='credit'
group by t.id,t.business_id,t.customer_id,t.transaction_no,t.total,t.due_date,t.status;


-- FINAL DATA INTEGRITY
alter table public.irkop_cell_products drop constraint if exists irkop_cell_products_stock_nonnegative;
alter table public.irkop_cell_products add constraint irkop_cell_products_stock_nonnegative check (stock >= 0);
alter table public.irkop_cell_products drop constraint if exists irkop_cell_products_sell_price_nonnegative;
alter table public.irkop_cell_products add constraint irkop_cell_products_sell_price_nonnegative check (sell_price >= 0);
alter table public.irkop_cell_transactions drop constraint if exists irkop_cell_transactions_total_nonnegative;
alter table public.irkop_cell_transactions add constraint irkop_cell_transactions_total_nonnegative check (total >= 0);
create or replace function public.irkop_cell_touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists irkop_cell_products_touch_updated_at on public.irkop_cell_products;
create trigger irkop_cell_products_touch_updated_at before update on public.irkop_cell_products for each row execute function public.irkop_cell_touch_updated_at();
drop trigger if exists irkop_cell_customers_touch_updated_at on public.irkop_cell_customers;
create trigger irkop_cell_customers_touch_updated_at before update on public.irkop_cell_customers for each row execute function public.irkop_cell_touch_updated_at();
drop trigger if exists irkop_cell_transactions_touch_updated_at on public.irkop_cell_transactions;
create trigger irkop_cell_transactions_touch_updated_at before update on public.irkop_cell_transactions for each row execute function public.irkop_cell_touch_updated_at();
