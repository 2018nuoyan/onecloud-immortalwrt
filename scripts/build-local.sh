#!/bin/bash
# Build under the project directory without touching other source trees.
# Usage: bash scripts/build-local.sh [LAN_IP] [use_ccache]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TAG=v25.12.2
COMMIT=4fc16f2985a358bd43bb522e43f05395fcbd6ed5
JOBS="${JOBS:-8}"
LAN_IP="${1:-10.10.10.1}"
USE_CCACHE="${2:-true}"
STAGE=setup
trap 'rc=$?; printf "stage=%s\nexit_code=%s\nfinished=%s\n" "$STAGE" "$rc" "$(date -Is)" > "$ROOT/build.status"' EXIT
cd "$ROOT"
if [ ! -d openwrt ]; then
	git clone --depth=1 --single-branch --branch "$TAG" \
		https://github.com/immortalwrt/immortalwrt.git openwrt
fi
[ "$(git -C openwrt rev-parse HEAD)" = "$COMMIT" ] || {
	echo "openwrt/ is not the expected ImmortalWrt $TAG commit; refusing to overwrite it" >&2
	exit 1
}
cp -a target openwrt/
mkdir -p openwrt/files
cp -a files/. openwrt/files/
chmod +x openwrt/target/linux/amlogic/image/*.sh \
	openwrt/files/usr/sbin/onecloud-install-emmc \
	openwrt/files/etc/uci-defaults/* \
	openwrt/target/linux/amlogic/base-files/etc/board.d/* \
	openwrt/target/linux/amlogic/base-files/etc/uci-defaults/*
cd openwrt
bash "$ROOT/scripts/diy-part1.sh"
STAGE=feeds
./scripts/feeds update -a
./scripts/feeds install -a
cp "$ROOT/config/onecloud.config" .config
bash "$ROOT/scripts/diy-part2.sh" "$LAN_IP" "$USE_CCACHE"
STAGE=defconfig
make defconfig
bash "$ROOT/scripts/verify-config.sh"
STAGE=prereq
make prereq
STAGE=kernel-prepare
make target/linux/prepare -j"$JOBS" V=s
STAGE=download
make download -j"$JOBS"
STAGE=compile
make -j"$JOBS" || make -j1 V=s
STAGE=complete
ls -lh bin/targets/amlogic/meson8b/
# USB Burning Tool packaging is a separate GitHub Actions step.
