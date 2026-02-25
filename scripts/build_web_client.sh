#!/usr/bin/env bash
# Build client app (Flutter) for deployment at /client_app/
# Usage: ./scripts/build_web_client.sh
# Output: deploy/client_app/

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR/client_app"

echo "Building MatGo client app for /client_app/..."
flutter build web --release --base-href "/client_app/"

OUT_DIR="$ROOT_DIR/deploy/client_app"
mkdir -p "$OUT_DIR"
rm -rf "$OUT_DIR"
cp -r build/web "$OUT_DIR"

echo "Done. Deploy contents of: $OUT_DIR"
echo "  → Upload to your server under path: /client_app/"
echo "  → Or run: firebase deploy --only hosting"
