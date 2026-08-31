#!/usr/bin/env bash
set -euo pipefail

echo "IRKOP final preflight"

required=(
  "../supabase/migrations/20260831000500_complete_schema_alignment.sql"
  "pubspec.yaml"
  "lib"
)

for path in "${required[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Missing required path: $path" >&2
    exit 1
  fi
done

migration="../supabase/migrations/20260831000500_complete_schema_alignment.sql"

for token in   "irkop_cell_outlets"   "irkop_cell_devices"   "irkop_cell_credit_payments"   "irkop_cell_product_stock_movements"   "irkop_cell_audit_logs" "irkop_cell_credit_balances" "irkop_cell_touch_updated_at"; do
  grep -q "$token" "$migration" || {
    echo "Schema alignment is incomplete: missing $token" >&2
    exit 1
  }
done

echo "Preflight passed."
