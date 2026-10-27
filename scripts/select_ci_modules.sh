#!/bin/bash
# Print a JSON array of CI modules for DATA_SOURCE.
#
# HAS_AWS_SECRETS=true keeps the full matrix. Cloud warehouses authenticate
# through AWS Secrets Manager, so when those build credentials are absent the
# matrix is limited to engines that run in local containers (postgres, sqlserver).
# An explicit cloud selection exits 1 instead of queueing a job that cannot log in.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_SOURCE="${DATA_SOURCE:-all}"
HAS_AWS_SECRETS="${HAS_AWS_SECRETS:-false}"

if [ "$DATA_SOURCE" = "all" ]; then
  MODULES="$(bash "$SCRIPT_DIR/test_matrix.sh")"
else
  MODULES="$(printf '["%s"]' "$DATA_SOURCE")"
fi

if [ "$HAS_AWS_SECRETS" != "true" ]; then
  echo "::notice::AWS build credentials are not configured. Running only local data sources (postgres, sqlserver)." >&2
  MODULES="$(
    printf '%s' "$MODULES" | python3 -c 'import json,sys; mods=json.load(sys.stdin); print(json.dumps([m for m in mods if m in ("postgres", "sqlserver")], separators=(",", ":")))'
  )"
  if [ "$MODULES" = "[]" ]; then
    echo "::error::${DATA_SOURCE} requires AWS Secrets Manager credentials (AWS_BUILD_ACCESS_KEY_ID, AWS_BUILD_SECRET_ACCESS_KEY, AWS_BUILD_DEFAULT_REGION)." >&2
    exit 1
  fi
fi

printf '%s\n' "$MODULES"
