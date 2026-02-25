#!/usr/bin/env bash
# Build admin app for deployment at /admin/
# Usage: ./scripts/build_web_admin.sh
# Output: deploy/admin/
# Zdroj: admin_shop_app/ (Flutter projekt)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR/admin_shop_app"

if [ ! -f pubspec.yaml ]; then
  echo "Error: admin_shop_app/pubspec.yaml not found. Run 'flutter create' in admin_shop_app/ first."
  exit 1
fi

echo "Building MatGo admin for /admin/..."
flutter build web --release --base-href "/admin/"

OUT_DIR="$ROOT_DIR/deploy/admin"
mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR"
cp -r build/web "$OUT_DIR"

echo "Done. Deploy: $OUT_DIR → firebase deploy --only hosting"
echo "  URL: https://tvoja-domena/admin/"
