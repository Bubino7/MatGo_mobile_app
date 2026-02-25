#!/usr/bin/env bash
# Build shop_app for deployment at /shop_app/
# Usage: ./scripts/build_web_shop.sh
# Output: deploy/shop_app/
# Predpoklad: v shop_app/ je platný Flutter projekt (flutter create .)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR/shop_app"

if [ ! -f pubspec.yaml ]; then
  echo "Error: shop_app/pubspec.yaml not found. Run 'flutter create' in shop_app/ first."
  exit 1
fi

echo "Building MatGo shop_app for /shop_app/..."
flutter build web --release --base-href "/shop_app/"

OUT_DIR="$ROOT_DIR/deploy/shop_app"
mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR"
cp -r build/web "$OUT_DIR"

echo "Done. Deploy: $OUT_DIR → firebase deploy --only hosting"
echo "  URL: https://tvoja-domena/shop_app/"
