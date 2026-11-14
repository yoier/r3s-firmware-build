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
# This script was created by yoier <https://github.com/yoier/r3s-firmware-build/blob/main/diy-part2.sh>
nowDate=`TZ="UTC-8" date "+%Y-%m-%d %H:%M:%S"`
if [[ $1 == 'pre' ]]; then ver=快照版; else ver=稳定版; fi 
sed -i "/return table/i table.appendChild(E('tr', { 'class': 'tr' }, [E('td', { 'class': 'td left', 'width': '33%' }, ['仓库地址 | 构建时间 | 版本']),E('td', { 'class': 'td left' }, [E('a', { 'href': 'https://github.com/yoier/r3s-firmware-build', 'target': '_blank' }, 'Powered by yoier/r3s-firmware-build | $nowDate | $ver')])]));" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
chmod +x files/scripts/*.sh
sed -i '/CONFIG_SQUASHFS_DECOMP_MULTI_PERCPU/d' target/linux/rockchip/armv8/config-6.12
cat >> target/linux/rockchip/armv8/config-6.12 <<'EOF'
CONFIG_GENERIC_IRQ_KEXEC_CLEAR_VM_FORWARD=y
CONFIG_NETKIT=y
EOF
# CONFIG_ARM_PMU=y
# CONFIG_ARM_PMUV3=y
# CONFIG_BPF_EVENTS=y
# CONFIG_CONTEXT_SWITCH_TRACER=y
# CONFIG_DYNAMIC_EVENTS=y
# # CONFIG_ENABLE_DEFAULT_TRACERS is not set
# CONFIG_EVENT_TRACING=y
# CONFIG_FTRACE=y
# # CONFIG_FTRACE_SYSCALLS is not set
# ?CONFIG_GENERIC_IRQ_KEXEC_CLEAR_VM_FORWARD=y
# CONFIG_GLOB=y
# # CONFIG_HIST_TRIGGERS is not set
# CONFIG_KPROBES=y
# CONFIG_KPROBE_EVENTS=y
# CONFIG_KRETPROBES=y
# CONFIG_MODULES_TREE_LOOKUP=y
# ?CONFIG_NETKIT=y
# CONFIG_NOP_TRACER=y
# CONFIG_PERF_EVENTS=y
# CONFIG_PROBE_EVENTS=y
# CONFIG_RING_BUFFER=y
# CONFIG_TRACEPOINTS=y
# CONFIG_TRACING=y