#!/usr/bin/env bash

set -euo pipefail

test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT

valid_json="$test_dir/valid.json"
valid_output="$test_dir/valid.md"
invalid_json="$test_dir/invalid.json"
invalid_text="$test_dir/invalid.txt"

cat > "$valid_json" <<'JSON'
{
  "verdict": "Aprovar com ressalvas",
  "observations": [
    {
      "level": "Importante",
      "location": "lib/example.dart:10",
      "problem": "O cenário offline não está coberto.",
      "correction": "Adicione um teste que valide o fallback do cache."
    }
  ],
  "strengths": ["A alteração mantém a separação entre camadas."],
  "remark": "Parece estável neste universo — por enquanto."
}
JSON

cat > "$invalid_json" <<'JSON'
{
  "verdict": "Aprovar",
  "observations": [],
  "strengths": [],
  "remark": "",
  "extra": "não permitido"
}
JSON

cat > "$invalid_text" <<'TEXT'
### Revisão de Contexto
Arquivos de contexto de revisão faltam ou estão vazios; Rick não foi chamado.
TEXT

bash tool/format_review_output.sh "$valid_json" "$valid_output"
rg -Fq '### 🧪 Veredito' "$valid_output"
rg -Fq '### 🚨 Observações' "$valid_output"
rg -Fq '### ✅ O que está bom' "$valid_output"
rg -Fq 'Parece estável neste universo' "$valid_output"

if bash tool/format_review_output.sh "$invalid_json" "$test_dir/invalid-json.md" >/dev/null 2>&1; then
  echo "Expected invalid JSON to be rejected." >&2
  exit 1
fi

if bash tool/format_review_output.sh "$invalid_text" "$test_dir/invalid-text.md" >/dev/null 2>&1; then
  echo "Expected the previous free-form response to be rejected." >&2
  exit 1
fi

echo "Structured review output tests passed."
