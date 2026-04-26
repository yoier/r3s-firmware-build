#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
# This script was created by yoier <https://github.com/yoier/r3s-firmware-build/blob/main/diy-part1.sh>
sed -i 's|https://git.openwrt.org/feed/packages.git|https://github.com/openwrt/packages.git|g' feeds.conf.default
sed -i 's|https://git.openwrt.org/project/luci.git|https://github.com/openwrt/luci.git|g' feeds.conf.default
sed -i 's|https://git.openwrt.org/feed/routing.git|https://github.com/openwrt/routing.git|g' feeds.conf.default
sed -i 's|https://git.openwrt.org/feed/telephony.git|https://github.com/openwrt/telephony.git|g' feeds.conf.default
cat > feeds.tmp <<'EOF'
src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main
src-git passwall2 https://github.com/Openwrt-Passwall/openwrt-passwall2.git;main
src-git kenzo https://github.com/kenzok8/openwrt-packages.git;master
EOF
cat feeds.conf.default >> feeds.tmp
mv feeds.tmp feeds.conf.default
git clone https://github.com/hudra0/qosmate.git package/qosmate
git clone https://github.com/hudra0/luci-app-qosmate.git package/luci-app-qosmate