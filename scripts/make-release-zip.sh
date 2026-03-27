#!/usr/bin/env bash
# Собирает zip для загрузки на CurseForge / WoWInterface и т.п.
# Без .git, __MACOSX, ._*, .vscode / .cursor (не попадают в «blacklisted»).
set -euo pipefail
ADDON_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$(basename "$ADDON_ROOT")"
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

OUT="${ADDON_ROOT}/${NAME}-release.zip"
rm -f "$OUT"
(
  cd "$STAGE"
  COPYFILE_DISABLE=1 zip -rq "$OUT" "$NAME"
)

echo "Created: $OUT"
echo "Inside: one folder \"$NAME/\" with HardcoreChallenges.toc at top level."
