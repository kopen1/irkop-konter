-- Repair migration for existing databases that predate outlet active status.
alter table public.irkop_cell_outlets
  add column if not exists is_active boolean not null default true;
