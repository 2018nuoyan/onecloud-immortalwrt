#!/bin/bash
# Runs inside the OpenWrt tree before `feeds update`.
# Keep the feeds pinned by the ImmortalWrt release tag.
set -e
echo "diy-part1: using release-pinned ImmortalWrt feeds.conf.default"
