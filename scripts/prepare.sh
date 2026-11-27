#!/usr/bin/env bash
set -euo pipefail

overlay_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dry_run=false
if [[ ${1:-} == --dry-run ]]; then
  dry_run=true
  shift
fi
if [[ $# != 3 || ! $1 =~ ^v[0-9]+\.[0-9]+\.[0-9]+-nightly\.[0-9]{8}\.[0-9]+$ || ! $2 =~ ^[0-9a-f]{40}$ ]]; then
  echo "Usage: $0 [--dry-run] NIGHTLY_TAG UPSTREAM_COMMIT NEW_CHECKOUT" >&2
  exit 2
fi
tag=$1
commit=$2
destination=$3
remote=https://github.com/pingdotgg/t3code.git
base_commit=$(jq -er '.commit | select(test("^[0-9a-f]{40}$"))' "$overlay_dir/upstream.json")
patches=("$overlay_dir"/patches/*.patch)

if $dry_run; then
  printf 'Prepare %s (%s) from %s in %s with %s patches\n' "$tag" "$commit" "$remote" "$destination" "${#patches[@]}"
  exit 0
fi
if [[ -e $destination ]]; then
  echo "Choose a new checkout path. This path already exists: $destination" >&2
  exit 2
fi

git clone --quiet --depth 1 --single-branch --branch "$tag" -- "$remote" "$destination"
if [[ $(git -C "$destination" rev-parse HEAD) != "$commit" ]]; then
  echo "$tag points at a different commit from the requested $commit" >&2
  exit 1
fi
if [[ $commit != "$base_commit" ]]; then
  git -C "$destination" fetch --quiet --no-tags --depth 1 origin "$base_commit"
fi
git -C "$destination" \
  -c user.name="H3 Code" -c user.email="github-actions[bot]@users.noreply.github.com" \
  -c commit.gpgSign=false -c core.hooksPath=/dev/null am --3way "${patches[@]}"

shopt -s nullglob
for path in "$destination"/assets/{prod,nightly,dev}/*.{png,ico}; do
  case $path in
    *.ico) icon=h3.ico ;;
    *1024.png) icon=h3-1024.png ;;
    *512x512.png) icon=h3-512.png ;;
    *192x192.png) icon=h3-192.png ;;
    *180.png) icon=h3-180.png ;;
    *32x32.png) icon=h3-32.png ;;
    *16x16.png) icon=h3-16.png ;;
    *) continue ;;
  esac
  cp "$overlay_dir/brand/$icon" "$path"
done
