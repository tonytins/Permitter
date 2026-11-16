#!/usr/bin/env bash
#
# Refreshes the vendored Choose A License license texts.
#
# The upstream files carry YAML front matter for the choosealicense.com
# website. This script verifies each file's spdx-id, strips the front matter,
# and writes a body-only file named <SPDX-ID>.txt. It never edits the metadata
# in licenses.json and never touches CDDL-1.1.txt, which is the SPDX fallback.
#
# Usage:
#   Scripts/vendor-choosealicense.sh [COMMIT]
#
# Builds stay offline: the vendored files are committed, and this script is
# run by hand when the data is refreshed.

set -euo pipefail

readonly default_commit="af50be9eb902b4329e70c33a5f5c9bab891ef26d"
readonly repository="https://github.com/github/choosealicense.com.git"
readonly expected_licenses=47
readonly fallback_license="CDDL-1.1"

script_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly package_root="$(cd "$script_directory/.." && pwd)"
readonly resources="$package_root/Sources/Permitter/Resources/LicenseData"
readonly license_directory="$resources/licenses"
readonly commit_file="$resources/ChooseALicense.commit"

commit="${1:-$default_commit}"
work_directory="$(mktemp -d)"
trap 'rm -rf "$work_directory"' EXIT

echo "Fetching choosealicense.com at $commit..."
git clone --quiet --filter=blob:none --no-checkout "$repository" "$work_directory/repository"
git -C "$work_directory/repository" sparse-checkout init --cone
git -C "$work_directory/repository" sparse-checkout set _licenses
git -C "$work_directory/repository" checkout --quiet "$commit"

if ! git -C "$work_directory/repository" rev-parse --verify --quiet \
    "$commit^{commit}" >/dev/null; then
    echo "error: $commit is not a commit in $repository" >&2
    exit 1
fi

mkdir -p "$license_directory"
ids_file="$work_directory/ids"
: >"$ids_file"

count=0
for source in "$work_directory"/repository/_licenses/*.txt; do
    id="$(sed -n 's/^spdx-id:[[:space:]]*//p' "$source" | head -n 1)"

    if [[ -z "$id" ]]; then
        echo "error: $source has no spdx-id" >&2
        exit 1
    fi

    if grep -Fxq "$id" "$ids_file"; then
        echo "error: duplicate spdx-id $id" >&2
        exit 1
    fi
    printf '%s\n' "$id" >>"$ids_file"

    awk '
        /^---$/ { boundaries++; next }
        boundaries >= 2 {
            if (!started && $0 == "") {
                next
            }
            started = 1
            print
        }
    ' "$source" >"$license_directory/$id.txt"

    if [[ ! -s "$license_directory/$id.txt" ]]; then
        echo "error: wrote an empty file for $id" >&2
        exit 1
    fi

    count=$((count + 1))
done

if [[ "$count" -ne "$expected_licenses" ]]; then
    echo "error: expected $expected_licenses licenses, found $count." >&2
    echo "Update the script and licenses.json deliberately." >&2
    exit 1
fi

while IFS= read -r file; do
    id="$(basename "$file" .txt)"
    if [[ "$id" == "$fallback_license" ]]; then
        continue
    fi
    if ! grep -Fxq "$id" "$ids_file"; then
        echo "error: stale vendored license $id." >&2
        echo "Remove it and its licenses.json entry before rerunning." >&2
        exit 1
    fi
done < <(find "$license_directory" -maxdepth 1 -name '*.txt' -print | sort)

printf '%s\n' "$commit" >"$commit_file"

echo "Vendored $count licenses at $commit."
echo "Review the text changes. If IDs changed, update licenses.json first."
echo "Then run Scripts/generate-license-list.sh, swift build, and swift test."
