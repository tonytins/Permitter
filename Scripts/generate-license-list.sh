#!/usr/bin/env bash
#
# Regenerates LIST.md from the vendored license metadata.
#
# LIST.md is committed so the roster can be read on GitHub without building
# Permitter. LicenseCatalogTests fails when the file drifts from the catalog,
# so run this after adding or removing a license or exception.
#
# The generator validates the data first, so a broken catalog cannot produce
# a list.

set -euo pipefail

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly package_root="$(cd "$script_directory/.." && pwd)"
readonly resources="$package_root/Sources/Permitter/Resources/LicenseData"
readonly output="$package_root/LIST.md"

cd "$package_root"

swift build --quiet --product GenerateLicenseCatalog
generator="$(swift build --show-bin-path)/GenerateLicenseCatalog"

"$generator" --resources "$resources" --list "$output"

echo "Wrote $output."
