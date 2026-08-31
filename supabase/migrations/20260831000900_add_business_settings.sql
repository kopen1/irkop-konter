-- IRKOP Konter: persistent business and receipt settings.
create table if not exists public.irkop_cell_business_settings (
  business_id uuid primary key references public.irkop_cell_businesses(id) on delete cascade,
  address text not null default '',
  receipt_header text not null default 'TERIMA KASIH ATAS KUNJUNGAN ANDA',
  receipt_footer text not null default 'Semoga harimu menyenangkan!',
  dark_mode boolean not null default false,
  auto_input boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.irkop_cell_business_settings enable row level security;

drop policy if exists "owners manage business settings" on public.irkop_cell_business_settings;
create policy "owners manage business settings"
on public.irkop_cell_business_settings
for all to authenticated
using (
  exists (
    select 1 from public.irkop_cell_businesses b
    where b.id = business_id and b.owner_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.irkop_cell_businesses b
    where b.id = business_id and b.owner_user_id = auth.uid()
  )
);

drop trigger if exists irkop_cell_business_settings_touch_updated_at on public.irkop_cell_business_settings;
create trigger irkop_cell_business_settings_touch_updated_at
before update on public.irkop_cell_business_settings
for each row execute function public.irkop_cell_touch_updated_at();
