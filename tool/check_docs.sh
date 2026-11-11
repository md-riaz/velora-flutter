#!/usr/bin/env bash
# Checks that docs match shipped code (see packages/velora_cli/tool/check_docs.dart).
# Pass --write to regenerate the registry-derived doc blocks first.
set -euo pipefail
cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)/packages/velora_cli"
dart pub get >/dev/null
exec dart run tool/check_docs.dart "$@"
