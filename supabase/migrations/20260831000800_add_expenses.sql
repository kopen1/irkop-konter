-- IRKOP Konter expenses: operational expense ledger.
create table if not exists public.irkop_cell_expenses (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.irkop_cell_businesses(id) on delete cascade,
  outlet_id uuid references public.irkop_cell_outlets(id) on delete set null,
  category text not null default 'Operasional',
  amount numeric(14,2) not null check (amount > 0),
  description text,
  expense_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists irkop_cell_expenses_business_at_idx on public.irkop_cell_expenses(business_id, expense_at desc);
alter table public.irkop_cell_expenses enable row level security;
drop policy if exists "owners manage expenses" on public.irkop_cell_expenses;
create policy "owners manage expenses" on public.irkop_cell_expenses for all to authenticated
using (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()))
with check (exists (select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));
drop trigger if exists irkop_cell_expenses_touch_updated_at on public.irkop_cell_expenses;
create trigger irkop_cell_expenses_touch_updated_at before update on public.irkop_cell_expenses for each row execute function public.irkop_cell_touch_updated_at();