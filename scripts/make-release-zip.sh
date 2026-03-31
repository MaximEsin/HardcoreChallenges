#!/usr/bin/env bash
# Собирает zip для загрузки на CurseForge / WoWInterface и т.п.
# Без .git, __MACOSX, ._*, .vscode / .cursor (не попадают в «blacklisted»).
set -euo pipefail
ADDON_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$(basename "$ADDON_ROOT")"
TOC="$ADDON_ROOT/${NAME}.toc"
VERSION="$(grep -m1 '^## Version:' "$TOC" 2>/dev/null | sed 's/^## Version:[[:space:]]*//;s/[[:space:]]*$//' || true)"
if [[ -z "$VERSION" ]]; then
  echo "Warning: could not read ## Version from $TOC, using 'unknown'." >&2
  VERSION="unknown"
fi
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

rsync -a \
  --exclude='.git' \
  --exclude='.DS_Store' \
  --exclude='__MACOSX' \
  --exclude='.vscode' \
  --exclude='.cursor' \
  --exclude='.agent-transcripts' \
  --exclude='._*' \
  --exclude='scripts' \
  "$ADDON_ROOT/" "$STAGE/$NAME/"

OUT="${ADDON_ROOT}/${NAME}-${VERSION}-release.zip"
rm -f "$OUT"
# remove legacy unversioned zip if present
rm -f "${ADDON_ROOT}/${NAME}-release.zip"
(
  cd "$STAGE"
  COPYFILE_DISABLE=1 zip -rq "$OUT" "$NAME"
)

echo "Created: $OUT (version $VERSION from .toc)"
echo "Inside: one folder \"$NAME/\" with ${NAME}.toc at top level."
