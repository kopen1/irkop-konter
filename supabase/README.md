# Supabase Automation

Production migrations are applied automatically by GitHub Actions when files under `supabase/migrations/` change on `master`.

Required GitHub Actions secrets:
- SUPABASE_ACCESS_TOKEN
- SUPABASE_PROJECT_REF
- SUPABASE_URL
- SUPABASE_ANON_KEY

The random demo seed is intentionally NOT executed automatically against production. It is development/staging-only.

Before the first production migration, inspect the database and confirm that the migration draft matches the new project's intended schema.
