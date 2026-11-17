#!/usr/bin/env bash
# One-time setup: adds the Android/iOS/web platform folders that
# `flutter create` generates, then fetches packages for every project.
# Safe to re-run: flutter create only adds missing files.
set -euo pipefail
cd "$(dirname "$0")/.."
ORG=za.co.spongebubble

create() { # dir project-name platforms
  (cd "$1" && flutter create --org "$ORG" --project-name "$2" --platforms="$3" . >/dev/null && rm -f test/widget_test.dart && flutter pub get)
  echo "✓ $1"
}

(cd packages/sb_core && dart pub get) && echo "✓ packages/sb_core"
(cd packages/sb_ui && flutter pub get) && echo "✓ packages/sb_ui"
create apps/customer spongebubble_customer android,ios,web
create apps/partner spongebubble_partner android,ios
create apps/admin spongebubble_admin web

echo
echo "Done. Try:  cd apps/customer && flutter run -d chrome"
