#!/bin/bash
# Run from the configured ImmortalWrt source tree.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
missing=0
while read -r sym; do
	grep -qx "$sym" .config || { echo "MISSING: $sym" >&2; missing=1; }
done < <(grep -E '^CONFIG_PACKAGE_[A-Za-z0-9._+-]+=y$' "$ROOT/config/onecloud.config")
for sym in \
	CONFIG_TARGET_amlogic_meson8b_DEVICE_thunder-onecloud=y \
	CONFIG_KERNEL_ZRAM_BACKEND_LZ4=y \
	CONFIG_KERNEL_ZRAM_DEF_COMP_LZ4=y \
	CONFIG_IB=y CONFIG_IB_STANDALONE=y CONFIG_SDK=y; do
	grep -qx "$sym" .config || { echo "MISSING: $sym" >&2; missing=1; }
done
[ "$missing" = 0 ] || exit 1
echo "All requested packages, target and build tools survived defconfig"
