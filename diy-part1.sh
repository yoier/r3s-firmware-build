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
echo 'src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2' >>feeds.conf.default
echo 'src-git passpackages https://github.com/xiaorouji/openwrt-passwall-packages' >>feeds.conf.default
echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >>feeds.conf.default
git clone https://github.com/hudra0/qosmate.git package/qosmate
git clone https://github.com/hudra0/luci-app-qosmate.git package/luci-app-qosmate