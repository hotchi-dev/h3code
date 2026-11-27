#!/usr/bin/env bash
set -euo pipefail

dry_run=false
if [[ ${1:-} == --dry-run ]]; then
  dry_run=true
  shift
fi
if [[ $# -lt 5 || $# -gt 6 ]]; then
  echo "Usage: $0 [--dry-run] UPSTREAM_DIR PLATFORM ARCH TAG OUTPUT_DIR [WSL_ARCHIVE]" >&2
  exit 2
fi
source_dir=$1
platform=$2
arch=$3
tag=$4
artifacts=$5
wsl_archive=${6:-}
version=${tag#v}
case "$platform/$arch" in
  linux/x64)
    target=AppImage
    rust_target=x86_64-unknown-linux-gnu
    monitor=t3-resource-monitor
    ;;
  mac/arm64)
    target=dmg
    rust_target=aarch64-apple-darwin
    monitor=t3-resource-monitor
    ;;
  win/x64)
    target=nsis
    rust_target=x86_64-pc-windows-msvc
    monitor=t3-resource-monitor.exe
    if [[ -z $wsl_archive || ! -f $wsl_archive ]]; then
      echo "Windows packaging requires the Linux x64 CLI archive for the same build." >&2
      exit 2
    fi
    ;;
  *)
    echo "Unsupported H3 Code build target: $platform/$arch" >&2
    exit 2
    ;;
esac
if $dry_run; then
  printf 'Package %s %s as %s from %s to %s\n' "$platform/$arch" "$tag" "$target" "$source_dir" "$artifacts"
  exit 0
fi

mkdir -p "$artifacts/desktop" "$artifacts/cli"
artifacts=$(cd "$artifacts" && pwd)
cd "$source_dir"
export T3CODE_DESKTOP_UPDATE_REPOSITORY=${T3CODE_DESKTOP_UPDATE_REPOSITORY:-hotchi-dev/h3code}

packaging_args=()
if [[ -n $wsl_archive ]]; then
  packaging_args+=(--wsl-runtime "$wsl_archive")
fi
pnpm exec vp run dist:desktop:artifact \
  --platform "$platform" --target "$target" --arch "$arch" --build-version "$version" \
  --output-dir "$artifacts/desktop" "${packaging_args[@]}"

monitor_dir=$(mktemp -d)
trap 'rm -f "$monitor_dir/$monitor"; rmdir "$monitor_dir"' EXIT
# Reuse the binary just built by desktop packaging.
cp "native/resource-monitor/target/$rust_target/release/$monitor" "$monitor_dir/"
pnpm exec node scripts/build-cli-archive.ts \
  --platform "$platform" --arch "$arch" --version "$version" \
  --resource-monitor-dir "$monitor_dir" --output-dir "$artifacts/cli"
pnpm exec node scripts/smoke-cli-archive.ts --archive "$artifacts"/cli/t3-* --expect-version "$version"
