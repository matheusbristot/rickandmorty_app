#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: bash tool/scan_review_context.sh DIFF_FILE FILES_FILE" >&2
  exit 2
fi

diff_file="$1"
files_file="$2"

if [[ ! -s "$diff_file" || ! -s "$files_file" ]]; then
  echo "::error::Review context files are missing or empty; automated review was not run."
  exit 1
fi

# Keep this list conservative and deterministic. Never print the matching value.
credential_pattern='(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|(AKIA|ASIA)[0-9A-Z]{16}|AIza[0-9A-Za-z_-]{20,}|npm_[A-Za-z0-9]{36}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
assignment_pattern="(database[_-]?url|api[_-]?key|secret|token|password|private[_-]?key)[[:space:]]*[:=][[:space:]]*(https?://|postgres(ql)?://|mysql://|redis://|[A-Za-z0-9_+/=-]{20,})"
quoted_assignment_pattern="(database[_-]?url|api[_-]?key|secret|token|password|private[_-]?key)[[:space:]]*[:=][[:space:]]*(\"|')(https?://|postgres(ql)?://|mysql://|redis://|[A-Za-z0-9_+/=-]{20,})(\"|')"
sensitive_path_pattern='(^|/)(\.env(\.[^/]*)?|[^/]+\.(pem|key|p12|pfx|jks|keystore)|id_(rsa|dsa|ecdsa|ed25519)|credentials(\.json)?|service-account(\.json)?)$'

if grep -E -i -q -- "$sensitive_path_pattern" "$files_file"; then
  echo "::error::A sensitive file path was changed; automated review was not run."
  echo "::notice::Review secrets and certificate files locally, then remove them from the pull request before retrying."
  exit 1
fi

if grep -E -q -- "$credential_pattern" "$diff_file" || \
  grep -E -i -q -- "$assignment_pattern" "$diff_file" || \
  grep -E -i -q -- "$quoted_assignment_pattern" "$diff_file"; then
  echo "::error::Potential credential detected in the pull request diff; automated review was not run."
  echo "::notice::Remove and rotate/revoke the credential before retrying the review."
  exit 1
fi

echo "Review context passed the sensitive-path and credential-pattern checks."
