-- Final outlet active-status repair.
-- Safe for existing projects and forces PostgREST to reload the schema cache.

alter table public.irkop_cell_outlets
  add column if not exists is_active boolean;

update public.irkop_cell_outlets
set is_active = true
where is_active is null;

alter table public.irkop_cell_outlets
  alter column is_active set default true;

alter table public.irkop_cell_outlets
  alter column is_active set not null;

create index if not exists irkop_cell_outlets_business_active_idx
  on public.irkop_cell_outlets(business_id, is_active);

-- Make the newly added column visible immediately to the Supabase REST schema cache.
notify pgrst, 'reload schema';
