# Supabase Automation

Schema migrations are applied automatically by GitHub Actions when files under `supabase/migrations/` change on `master`.

Required GitHub Actions secrets:
- SUPABASE_ACCESS_TOKEN
- SUPABASE_PROJECT_REF
- SUPABASE_URL
- SUPABASE_ANON_KEY

## Demo architecture

Supabase Preview Branches are not required.

The existing project contains a logical multi-tenant demo business:
- `irkop_cell_businesses.is_demo = true`
- all demo rows are scoped by `business_id`
- anonymous users may read only rows belonging to the demo business
- public demo writes are not allowed

Run `seed/irkop_cell_demo_seed.sql` manually in the Supabase SQL Editor after at least one Supabase Auth user exists. The seed skips automatically if a demo business already exists.

Never run demo seed data automatically against a customer tenant.
