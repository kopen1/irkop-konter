# IRKOP Konter

Native business application for Android APK and Web.

## Locked direction
- Android uses native Flutter, not a WebView wrapper.
- Web is delivered from the same Flutter application codebase.
- Backend target is the existing IRKOP Supabase ecosystem.
- Database changes are provided as migration files and must be audited before execution.
- No Supabase service_role key is ever shipped in the client.

## Quick start later
1. Configure SUPABASE_URL and SUPABASE_ANON_KEY.
2. Audit existing IRKOP Supabase schema.
3. Apply compatible migrations.
4. Load demo seed only in development/staging.
5. Build Android and Web from flutter_app.

## Current scope
Dashboard, transactions, cashier, products, customers, reports, outlets, devices, owner/business context, and future subscription/license support.
