#!/usr/bin/env bash
set -euo pipefail

echo "==> IRKOP final project run"

echo "==> Preflight"
bash ../.github/scripts/preflight.sh

echo "==> Dependencies"
flutter pub get

echo "==> Static analysis"
flutter analyze

echo "==> Test"
if [[ -d test ]] && find test -type f -name "*_test.dart" -print -quit | grep -q .; then
  flutter test
else
  echo "No Flutter tests found; skipping test step."
fi

echo "==> Release web build"
flutter build web --release --pwa-strategy=none --base-href "/irkop-konter/" \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

echo "==> Deployment cache-bust"
SHA="${GITHUB_SHA:-local}"
if [[ -f build/web/main.dart.js ]]; then
  mv build/web/main.dart.js "build/web/main.${SHA}.dart.js"
  sed -i "s/main\\.dart\\.js/main.${SHA}.dart.js/g" build/web/flutter_bootstrap.js
fi
if [[ -f build/web/index.html ]]; then
  sed -i "s#flutter_bootstrap\\.js#flutter_bootstrap.js?v=${SHA}#g" build/web/index.html
fi
printf '%s\n' "${SHA}" > build/web/BUILD_COMMIT.txt

echo "==> Final web output check"
test -f build/web/index.html
test -f build/web/flutter_bootstrap.js
test -f build/web/BUILD_COMMIT.txt

echo "==> FINAL PASS"
