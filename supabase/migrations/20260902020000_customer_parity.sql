create table if not exists public.irkop_cell_customer_aliases (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  customer_id uuid not null references public.irkop_cell_customers(id) on delete cascade,
  alias_type text not null default 'phone',
  alias_value text not null,
  source text not null default 'manual',
  created_at timestamptz not null default now()
);

create index if not exists idx_customer_alias_business
  on public.irkop_cell_customer_aliases(business_id);

create index if not exists idx_customer_alias_customer
  on public.irkop_cell_customer_aliases(customer_id);

alter table public.irkop_cell_customer_aliases enable row level security;

drop policy if exists customer_alias_owner on public.irkop_cell_customer_aliases;

create policy customer_alias_owner
on public.irkop_cell_customer_aliases
for all
using (
  business_id in (
    select business_id
    from public.irkop_cell_business_members
    where user_id = auth.uid()
  )
)
with check (
  business_id in (
    select business_id
    from public.irkop_cell_business_members
    where user_id = auth.uid()
  )
);

create table if not exists public.irkop_cell_customer_merges (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  source_customer_id uuid not null references public.irkop_cell_customers(id),
  target_customer_id uuid not null references public.irkop_cell_customers(id),
  created_at timestamptz not null default now()
);

create index if not exists idx_customer_merges_business
  on public.irkop_cell_customer_merges(business_id);

alter table public.irkop_cell_customer_merges enable row level security;

drop policy if exists customer_merges_owner on public.irkop_cell_customer_merges;

create policy customer_merges_owner
on public.irkop_cell_customer_merges
for all
using (
  business_id in (
    select business_id
    from public.irkop_cell_business_members
    where user_id = auth.uid()
  )
)
with check (
  business_id in (
    select business_id
    from public.irkop_cell_business_members
    where user_id = auth.uid()
  )
);
