# START HERE

IRKOP Konter is the new repository. The old `irkop-cell` repository remains legacy/reference and is not the deployment target.

## Architecture
Flutter Android APK + Flutter Web -> Supabase -> existing IRKOP ecosystem.

## Safety
The migration files are drafts until the real Supabase schema is audited. Do not run production SQL blindly.

## Demo
The application can start in demo mode when Supabase environment values are absent. SQL seed data is provided for staging/development.
