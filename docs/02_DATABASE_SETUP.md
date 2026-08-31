# Database Setup

Before running SQL:
1. Audit existing Supabase tables, auth model, and Panel integration.
2. Map any canonical IRKOP tenant/business tables.
3. Avoid duplicate entities.
4. Replace placeholder owner UUID in the demo seed.
5. Run migrations in a development project first.
6. Add child-table RLS policies based on the real tenant model.

Environment values used by Flutter:
- SUPABASE_URL
- SUPABASE_ANON_KEY

Never add SUPABASE service_role credentials to the mobile or web client.
