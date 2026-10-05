#!/bin/bash
# Run from the configured ImmortalWrt source tree.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-all}"
case "$MODE" in
	all|firmware|tools) ;;
	*) echo "Usage: $0 [all|firmware|tools]" >&2; exit 2 ;;
esac
missing=0
while read -r sym; do
	grep -qx "$sym" .config || { echo "MISSING: $sym" >&2; missing=1; }
done < <(grep -E '^CONFIG_PACKAGE_[A-Za-z0-9._+-]+=y$' "$ROOT/config/onecloud.config")
for sym in \
	CONFIG_TARGET_amlogic_meson8b_DEVICE_thunder-onecloud=y \
	CONFIG_KERNEL_ZRAM_BACKEND_LZ4=y \
	CONFIG_KERNEL_ZRAM_DEF_COMP_LZ4=y; do
	grep -qx "$sym" .config || { echo "MISSING: $sym" >&2; missing=1; }
done
for sym in CONFIG_IB CONFIG_IB_STANDALONE CONFIG_SDK; do
	if [ "$MODE" = firmware ]; then
		if grep -qx "$sym=y" .config; then
			echo "UNEXPECTED: $sym=y in firmware-only build" >&2
			missing=1
		fi
	else
		grep -qx "$sym=y" .config || { echo "MISSING: $sym=y" >&2; missing=1; }
	fi
done
[ "$missing" = 0 ] || exit 1
echo "Configuration verified for build mode: $MODE"
