#!/usr/bin/env bash
# Verifies the Velora toolchain baseline (see docs/toolchain.md):
#   1. the active Flutter and Dart SDKs are at or above the minimum,
#   2. every tracked pubspec.yaml declares the baseline constraints,
#   3. no source file imports a deprecated desktop `legacy.dart` library.
# Run from anywhere inside the repository. Exits non-zero on any violation.
set -euo pipefail

MIN_DART="3.13.0"
MIN_FLUTTER="3.47.0"

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
status=0
fail() {
  echo "✗ $1" >&2
  status=1
}

# True when $1 >= $2, comparing dotted numeric versions.
version_at_least() {
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# --- 1. Active toolchain -----------------------------------------------------
if [ "${1:-}" != "--pubspecs-only" ]; then
  flutter_version="$(flutter --version --machine | sed -n 's/.*"frameworkVersion": *"\([0-9.]*\).*/\1/p' | head -n1)"
  dart_version="$(dart --version 2>&1 | sed -n 's/.*Dart SDK version: *\([0-9.]*\).*/\1/p' | head -n1)"
  if [ -z "$flutter_version" ]; then
    fail "Could not read the Flutter version (is flutter on PATH?)."
  elif ! version_at_least "$flutter_version" "$MIN_FLUTTER"; then
    fail "Flutter $flutter_version is below the required >=$MIN_FLUTTER. Run \`flutter upgrade\`."
  else
    echo "✓ Flutter $flutter_version (required >=$MIN_FLUTTER)"
  fi
  if [ -z "$dart_version" ]; then
    fail "Could not read the Dart version (is dart on PATH?)."
  elif ! version_at_least "$dart_version" "$MIN_DART"; then
    fail "Dart $dart_version is below the required >=$MIN_DART. Run \`flutter upgrade\`."
  else
    echo "✓ Dart $dart_version (required >=$MIN_DART)"
  fi
fi

# --- 2. pubspec constraints --------------------------------------------------
# The inventory comes from git, so a new package cannot be skipped.
count=0
while IFS= read -r pubspec; do
  count=$((count + 1))
  env_block="$(awk '/^environment:/{p=1;next} p&&/^[^ #]/{p=0} p' "$pubspec")"
  if ! grep -qE "^  sdk: *['\"]?\^${MIN_DART//./\\.}['\"]?\s*$" <<<"$env_block"; then
    fail "$pubspec: environment.sdk must be ^$MIN_DART"
  fi
  has_flutter_constraint=0
  grep -qE "^  flutter:" <<<"$env_block" && has_flutter_constraint=1
  if grep -qE "^\s+sdk: flutter\s*$" "$pubspec"; then
    if ! grep -qE "^  flutter: *['\"]>=${MIN_FLUTTER//./\\.}['\"]\s*$" <<<"$env_block"; then
      fail "$pubspec: environment.flutter must be '>=$MIN_FLUTTER'"
    fi
  elif [ "$has_flutter_constraint" = 1 ]; then
    fail "$pubspec: pure Dart package must not declare environment.flutter"
  fi
done < <(git ls-files 'pubspec.yaml' '*/pubspec.yaml' | grep -v '^third_party/')
echo "✓ Checked $count pubspec.yaml files"

# --- 3. Deprecated desktop compatibility imports -----------------------------
legacy="$(git grep -nE "package:(window_manager|tray_manager|screen_retriever)/legacy\.dart" -- '*.dart' || true)"
if [ -n "$legacy" ]; then
  fail "Deprecated desktop legacy imports found:"
  echo "$legacy" >&2
fi

exit "$status"
