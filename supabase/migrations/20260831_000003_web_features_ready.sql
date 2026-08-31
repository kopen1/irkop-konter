-- IRKOP Konter: database preparation for staged web features.
alter table public.irkop_cell_customers add column if not exists email text, add column if not exists address text, add column if not exists notes text, add column if not exists is_active boolean not null default true, add column if not exists updated_at timestamptz not null default now();
alter table public.irkop_cell_products add column if not exists cost_price numeric(14,2) not null default 0, add column if not exists min_stock numeric(14,2) not null default 0, add column if not exists updated_at timestamptz not null default now();
alter table public.irkop_cell_transactions add column if not exists discount numeric(14,2) not null default 0, add column if not exists paid_amount numeric(14,2), add column if not exists due_date date, add column if not exists notes text, add column if not exists updated_at timestamptz not null default now();

create table if not exists public.irkop_cell_credit_payments (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
 transaction_id uuid not null references public.irkop_cell_transactions(id) on delete cascade,
 customer_id uuid references public.irkop_cell_customers(id) on delete set null,
 amount numeric(14,2) not null check(amount>0), paid_at timestamptz not null default now(), notes text, created_at timestamptz not null default now()
);
create table if not exists public.irkop_cell_product_stock_movements (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
 product_id uuid not null references public.irkop_cell_products(id) on delete cascade,
 transaction_id uuid references public.irkop_cell_transactions(id) on delete set null,
 movement_type text not null check(movement_type in ('in','out','adjustment','sale','reversal')),
 qty numeric(14,2) not null, stock_before numeric(14,2), stock_after numeric(14,2), notes text, occurred_at timestamptz not null default now()
);
create table if not exists public.irkop_cell_audit_logs (
 id uuid primary key default gen_random_uuid(),
 business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
 actor_user_id uuid references auth.users(id) on delete set null,
 entity_type text not null, entity_id uuid, action text not null,
 metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists irkop_cell_credit_payments_tx_idx on public.irkop_cell_credit_payments(business_id,transaction_id,paid_at desc);
create index if not exists irkop_cell_stock_movements_product_idx on public.irkop_cell_product_stock_movements(business_id,product_id,occurred_at desc);
create index if not exists irkop_cell_audit_logs_idx on public.irkop_cell_audit_logs(business_id,created_at desc);

alter table public.irkop_cell_credit_payments enable row level security;
alter table public.irkop_cell_product_stock_movements enable row level security;
alter table public.irkop_cell_audit_logs enable row level security;

drop policy if exists "owner manages own credit payments" on public.irkop_cell_credit_payments;
create policy "owner manages own credit payments" on public.irkop_cell_credit_payments for all to authenticated using (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));

drop policy if exists "owner manages own stock movements" on public.irkop_cell_product_stock_movements;
create policy "owner manages own stock movements" on public.irkop_cell_product_stock_movements for all to authenticated using (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));

drop policy if exists "owner manages own audit logs" on public.irkop_cell_audit_logs;
create policy "owner manages own audit logs" on public.irkop_cell_audit_logs for all to authenticated using (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check (exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));

create or replace view public.irkop_cell_daily_sales as
select business_id,outlet_id,transaction_at::date as sale_date,count(*) filter(where status='completed') as transaction_count,coalesce(sum(total) filter(where status='completed'),0) as revenue
from public.irkop_cell_transactions group by business_id,outlet_id,transaction_at::date;

create or replace view public.irkop_cell_credit_balances as
select t.id as transaction_id,t.business_id,t.customer_id,t.transaction_no,t.total,coalesce(sum(p.amount),0) as paid,greatest(t.total-coalesce(sum(p.amount),0),0) as balance,t.due_date,t.status
from public.irkop_cell_transactions t left join public.irkop_cell_credit_payments p on p.transaction_id=t.id
where t.payment_method='credit'
group by t.id,t.business_id,t.customer_id,t.transaction_no,t.total,t.due_date,t.status;
