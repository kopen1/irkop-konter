-- Persist the NotifHook configuration and activity log shown by Settings.
create table if not exists public.irkop_cell_notifhook_settings (
  business_id uuid primary key references public.irkop_cell_businesses(id) on delete cascade,
  enabled boolean not null default true,
  endpoint text not null default '',
  api_key text not null default '',
  source_midtrans boolean not null default true,
  source_xendit boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
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
create index if not exists irkop_cell_audit_logs_business_created_idx on public.irkop_cell_audit_logs(business_id,created_at desc);
alter table public.irkop_cell_notifhook_settings enable row level security;
alter table public.irkop_cell_audit_logs enable row level security;
drop policy if exists "owners manage notifhook settings" on public.irkop_cell_notifhook_settings;
create policy "owners manage notifhook settings" on public.irkop_cell_notifhook_settings for all to authenticated using(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid())) with check(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));
drop policy if exists "owners read audit logs" on public.irkop_cell_audit_logs;
create policy "owners read audit logs" on public.irkop_cell_audit_logs for select to authenticated using(exists(select 1 from public.irkop_cell_businesses b where b.id=business_id and b.owner_user_id=auth.uid()));
drop trigger if exists irkop_cell_notifhook_settings_touch_updated_at on public.irkop_cell_notifhook_settings;
create trigger irkop_cell_notifhook_settings_touch_updated_at before update on public.irkop_cell_notifhook_settings for each row execute function public.irkop_cell_touch_updated_at();
