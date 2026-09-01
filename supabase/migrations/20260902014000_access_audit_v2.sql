-- Infrastruktur audit/access tidak memaksa perubahan UI.
-- Buat tabel audit hanya jika belum tersedia.

create table if not exists public.irkop_cell_audit_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid,
  actor_id uuid,
  action text not null,
  entity_type text,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_irkop_cell_audit_logs_business
  on public.irkop_cell_audit_logs(business_id, created_at desc);

alter table public.irkop_cell_audit_logs enable row level security;
