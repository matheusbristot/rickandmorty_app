#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: bash tool/format_review_output.sh INPUT_JSON OUTPUT_MARKDOWN" >&2
  exit 2
fi

input_file="$1"
output_file="$2"

if [[ ! -s "$input_file" ]]; then
  echo "::error::The structured local review response is missing or empty." >&2
  exit 1
fi

if ! jq -e '
  type == "object" and
  ((keys_unsorted | sort) == ["observations", "remark", "strengths", "verdict"]) and
  (.verdict | type == "string" and
    (. == "Aprovar" or . == "Aprovar com ressalvas" or . == "Solicitar mudanças")) and
  (.observations | type == "array" and length <= 5 and
    all(.[];
      type == "object" and
      ((keys_unsorted | sort) == ["correction", "level", "location", "problem"]) and
      (.level | type == "string" and
        (. == "Bloqueador" or . == "Importante" or . == "Sugestão")) and
      (.location | type == "string" and length > 0 and length <= 160) and
      (.problem | type == "string" and length > 0 and length <= 1200) and
      (.correction | type == "string" and length > 0 and length <= 800)
    )) and
  (.strengths | type == "array" and length <= 3 and
    all(.[]; type == "string" and length > 0 and length <= 400)) and
  (.remark | type == "string" and length <= 240)
' "$input_file" >/dev/null; then
  echo "::error::The local reviewer returned JSON outside the trusted review contract." >&2
  exit 1
fi

jq -r '
  def one_line:
    gsub("[\\r\\n\\t]+"; " ")
    | gsub("`"; "")
    | gsub("[[:space:]]+"; " ")
    | .;
  "### 🧪 Veredito\n" + .verdict +
  "\n\n### 🚨 Observações\n" +
  (if (.observations | length) == 0 then
    "Nenhuma falha acionável encontrada neste diff."
  else
    (.observations |
      map("- **[" + .level + "] `" + (.location | one_line) +
        "`** — " + (.problem | one_line) +
        "\n  Correção sugerida: " + (.correction | one_line)) |
      join("\n"))
  end) +
  "\n\n### ✅ O que está bom\n" +
  (if (.strengths | length) == 0 then
    "Nenhum ponto positivo adicional foi registrado."
  else
    (.strengths | map("- " + (one_line)) | join("\n"))
  end) +
  (if (.remark | length) == 0 then "" else "\n\n> " + (.remark | one_line) end)
' "$input_file" > "$output_file"

if [[ ! -s "$output_file" ]]; then
  echo "::error::The formatted local review is empty." >&2
  exit 1
fi
