#!/usr/bin/env bash
# Build driver_app for deployment at /driver_app/
# Usage: ./scripts/build_web_driver.sh
# Output: deploy/driver_app/
# Predpoklad: v driver_app/ je platný Flutter projekt (flutter create .)

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR/driver_app"

if [ ! -f pubspec.yaml ]; then
  echo "Error: driver_app/pubspec.yaml not found. Run 'flutter create' in driver_app/ first."
  exit 1
fi

echo "Building MatGo driver_app for /driver_app/..."
flutter build web --release --base-href "/driver_app/"

OUT_DIR="$ROOT_DIR/deploy/driver_app"
mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR"
cp -r build/web "$OUT_DIR"

echo "Done. Deploy contents of: $OUT_DIR"
echo "  → firebase deploy --only hosting"
