#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
nowDate=`TZ="UTC-8" date "+%Y-%m-%d %H:%M:%S"`
sed -i "/return table/i table.appendChild(E('tr', { 'class': 'tr' }, [E('td', { 'class': 'td left', 'width': '33%' }, ['仓库地址 | 构建时间']),E('td', { 'class': 'td left' }, [E('a', { 'href': 'https://github.com/yoier/r2s-firmware-build', 'target': '_blank' }, 'Powered by yoier/r2s-firmware-build | $nowDate')])]));" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
chmod +x files/scripts/*.sh
