#!/usr/bin/env bash
# Resolves dependencies for every tracked package and example.
# Packages with a committed pubspec.lock are resolved with --enforce-lockfile,
# so a stale lockfile fails instead of being silently rewritten.
# Pass --upgrade-locks to refresh those lockfiles instead.
set -euo pipefail

cd "$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
mode="${1:-}"

while IFS= read -r pubspec; do
  dir="$(dirname "$pubspec")"
  tool=dart
  grep -qE "^\s+sdk: flutter\s*$" "$pubspec" && tool=flutter
  args=(pub get)
  if git ls-files --error-unmatch "$dir/pubspec.lock" >/dev/null 2>&1; then
    if [ "$mode" = "--upgrade-locks" ]; then
      args=(pub upgrade)
    else
      args=(pub get --enforce-lockfile)
    fi
  fi
  echo "::group::$dir — $tool ${args[*]}"
  (cd "$dir" && "$tool" "${args[@]}")
  echo "::endgroup::"
done < <(git ls-files 'pubspec.yaml' '*/pubspec.yaml' | grep -v '^third_party/')
