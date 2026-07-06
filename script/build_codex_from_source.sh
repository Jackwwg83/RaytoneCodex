#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_DIR="$ROOT_DIR/third_party/openai-codex"
BUILD_DIR="$ROOT_DIR/dist/RaytoneCodexCLI"
CODEX_OUT="$BUILD_DIR/codex"
SCHEMA_DIR="$ROOT_DIR/Schemas"
EXPERIMENTAL_SCHEMA_DIR="$SCHEMA_DIR/experimental"

PINNED_COMMIT="${RAYTONE_CODEX_SOURCE_COMMIT:-18ce671fed526be9033907bd88a3a63c6888bbf4}"
SOURCE_REMOTE="${RAYTONE_CODEX_SOURCE_REMOTE:-https://github.com/openai/codex.git}"

if [[ -d "$SOURCE_DIR" && ! -d "$SOURCE_DIR/.git" ]]; then
  rm -rf "$SOURCE_DIR"
fi

if [[ ! -d "$SOURCE_DIR/.git" ]]; then
  mkdir -p "$(dirname "$SOURCE_DIR")"
  if [[ -d "$SOURCE_REMOTE/.git" ]]; then
    git clone "$SOURCE_REMOTE" "$SOURCE_DIR"
  else
    git clone --filter=blob:none "$SOURCE_REMOTE" "$SOURCE_DIR"
  fi
fi

if [[ -d "$SOURCE_REMOTE/.git" ]]; then
  git -C "$SOURCE_DIR" fetch origin "$PINNED_COMMIT"
else
  git -C "$SOURCE_DIR" fetch --depth 1 origin "$PINNED_COMMIT"
fi
git -C "$SOURCE_DIR" switch --detach "$PINNED_COMMIT"

mkdir -p "$BUILD_DIR"
(
  cd "$SOURCE_DIR/codex-rs"
  cargo build --release --bin codex
)

cp "$SOURCE_DIR/codex-rs/target/release/codex" "$CODEX_OUT"
chmod +x "$CODEX_OUT"
if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$CODEX_OUT" >/dev/null
fi

rm -rf "$SCHEMA_DIR"
mkdir -p "$SCHEMA_DIR"
"$CODEX_OUT" app-server generate-json-schema --out "$SCHEMA_DIR"
mkdir -p "$EXPERIMENTAL_SCHEMA_DIR"
"$CODEX_OUT" app-server generate-json-schema --experimental --out "$EXPERIMENTAL_SCHEMA_DIR"

{
  if [[ -f "$SOURCE_DIR/NOTICE" ]]; then
    cat "$SOURCE_DIR/NOTICE"
    printf '\n\n'
  fi
  printf 'RaytoneCodex bundles a Codex CLI built from openai/codex@%s.\n' "$PINNED_COMMIT"
  printf 'Source repository: https://github.com/openai/codex\n'
  printf 'License: Apache-2.0; see OPENAI_CODEX_LICENSE.txt in the app bundle.\n'
} >"$SOURCE_DIR/RAYTONE_CODEX_NOTICE.txt"

printf '{\n'
printf '  "ok": true,\n'
printf '  "sourceDir": "%s",\n' "$SOURCE_DIR"
printf '  "sourceRemote": "%s",\n' "$SOURCE_REMOTE"
printf '  "commit": "%s",\n' "$PINNED_COMMIT"
printf '  "codex": "%s",\n' "$CODEX_OUT"
printf '  "version": "%s",\n' "$("$CODEX_OUT" --version | tr -d '\r')"
printf '  "schemas": "%s",\n' "$SCHEMA_DIR"
printf '  "experimentalSchemas": "%s"\n' "$EXPERIMENTAL_SCHEMA_DIR"
printf '}\n'
