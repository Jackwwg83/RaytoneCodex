#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_BIN="${RAYTONE_CODEX_CLI:-$ROOT_DIR/.build/raytone-codex-cli/codex}"

if [[ ! -x "$CODEX_BIN" ]]; then
  if command -v codex >/dev/null 2>&1; then
    CODEX_BIN="$(command -v codex)"
  else
    echo "missing executable codex binary: $CODEX_BIN" >&2
    exit 2
  fi
fi

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/raytone-schema-match.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

"$CODEX_BIN" app-server generate-json-schema --out "$tmp_dir/Schemas" >/dev/null
"$CODEX_BIN" app-server generate-json-schema --experimental --out "$tmp_dir/Schemas/experimental" >/dev/null

python3 - "$ROOT_DIR/Schemas" "$tmp_dir/Schemas" "$CODEX_BIN" <<'PY'
import hashlib
import json
import pathlib
import sys

repo = pathlib.Path(sys.argv[1])
generated = pathlib.Path(sys.argv[2])
codex = sys.argv[3]

repo_files = {path.relative_to(repo) for path in repo.rglob("*.json")}
generated_files = {path.relative_to(generated) for path in generated.rglob("*.json")}
only_repo = sorted(str(path) for path in repo_files - generated_files)
only_generated = sorted(str(path) for path in generated_files - repo_files)
semantic_diffs = []

for rel in sorted(repo_files & generated_files):
    try:
        repo_value = json.loads((repo / rel).read_text(encoding="utf-8"))
        generated_value = json.loads((generated / rel).read_text(encoding="utf-8"))
    except Exception as exc:
        semantic_diffs.append({"path": str(rel), "error": str(exc)})
        continue

    repo_canonical = json.dumps(repo_value, sort_keys=True, separators=(",", ":"))
    generated_canonical = json.dumps(generated_value, sort_keys=True, separators=(",", ":"))
    if repo_canonical != generated_canonical:
        semantic_diffs.append({
            "path": str(rel),
            "repoSha256": hashlib.sha256(repo_canonical.encode()).hexdigest(),
            "generatedSha256": hashlib.sha256(generated_canonical.encode()).hexdigest(),
        })

result = {
    "ok": not only_repo and not only_generated and not semantic_diffs,
    "codex": codex,
    "repoFiles": len(repo_files),
    "generatedFiles": len(generated_files),
    "onlyRepo": only_repo,
    "onlyGenerated": only_generated,
    "semanticDiffCount": len(semantic_diffs),
    "semanticDiffs": semantic_diffs[:20],
}
print(json.dumps(result, ensure_ascii=False, indent=2))
sys.exit(0 if result["ok"] else 1)
PY
