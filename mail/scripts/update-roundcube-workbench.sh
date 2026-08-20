#!/usr/bin/env sh
set -eu

REPO="AR-Sebastian/roundcube-skin-workbench"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MAIL_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SKINS_DIR="$MAIL_DIR/templates/roundcube/skins"
TARGET_DIR="$SKINS_DIR/workbench"
VERSION_FILE="$SKINS_DIR/workbench.version"

VERSION="${1:-}"
if [ -z "$VERSION" ] && [ -f "$VERSION_FILE" ]; then
  VERSION=$(sed -n '1p' "$VERSION_FILE")
fi
if [ -z "$VERSION" ]; then
  echo "Usage: $0 v1.2.1" >&2
  exit 1
fi

case "$VERSION" in
  v*) TAG="$VERSION" ;;
  *) TAG="v$VERSION" ;;
esac

VERSION_NUMBER=${TAG#v}
ARCHIVE_URL="https://github.com/$REPO/releases/download/$TAG/workbench-skin-$VERSION_NUMBER.tar.gz"
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/workbench-update.XXXXXX")

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

command -v curl >/dev/null 2>&1 || { echo "curl is required" >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "tar is required" >&2; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "rsync is required" >&2; exit 1; }

mkdir -p "$SKINS_DIR"
curl -fsSL "$ARCHIVE_URL" -o "$TMP_DIR/workbench.tar.gz"
tar -xzf "$TMP_DIR/workbench.tar.gz" -C "$TMP_DIR"

if [ ! -f "$TMP_DIR/workbench/meta.json" ]; then
  echo "Archive does not contain workbench/meta.json" >&2
  exit 1
fi

mkdir -p "$TARGET_DIR"
rsync -a --delete "$TMP_DIR/workbench/" "$TARGET_DIR/"
printf '%s\n' "$TAG" > "$VERSION_FILE"

echo "Workbench updated to $TAG"
