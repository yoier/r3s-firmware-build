## R3S固件-YEE
ext4文件系统，支持自动更新扩容(删除计划任务"#20 5 * * 1 /scripts/upgrade.sh online needback"前的注释以启用更新，更新时间为每周一凌晨5:20)，保存配置文件，固件包含scripts文件夹(仅在无emmc版本上测试过)，默认禁用tailscale启动项。<br>/scripts<br>└─first-boot.sh---每次系统更新后的首次启动都会运行该脚本。<br>└─otherbackfs.txt---使用脚本更新系统时要额外保留的文件/文件夹。<br>└─upgrade.sh---系统更新脚本。
- 系统更新默认会保留sysupgrade -b back.tar.gz输出的文件(通常包含/etc目录下的配置)。运行命令并打开压缩包查看默认保留文件，确保不会与otherbackfs.txt文件里的文件/文件夹重复，防止重复覆盖配置。
- upgrade.sh可选项online|offline needback|noback<br>online-在线下载固件并更新(确保您的网络与Github连接通畅)。<br>offline-离线更新，需要手动上传固件gz以及sha256sum到/tmp/upload文件夹下。<br>needback-保留配置文件以及otherbackfs.txt里的文件/文件夹。<br>noback-不保留配置文件。
- 挂载存储盘仅支持ext4格式，备份数据、格式化为ext4格式方可挂载。挂载ext4避免各种疑难杂症。
- tailscale默认处于禁用状态，如要启用终端执行service tailscale enable或管理页面>系统>启动项页面下手动开启。
---
2025.03.16
<br>文件系统ext4
<br>内核以及系统分区大小
<br>&ensp;ker:32M sys:256M
<br>包含的包
<br>&ensp;ffmepg ffprobe
<br>&ensp;passwall(nft xray hysteria) tailscale ttyd samba4
<br>&ensp;block-mount kmod-fs-ext4 usb2 usb3 bash python3(pip) vim-full sha256sum md5sum Customized-BusyBox shadow-full kmod-tcp-bbr
<br>&ensp;fdisk sfdisk losetup resize2fs coreutils-truncate coreutils-dd

## 插件配置教程
待整理

## 记录
- 2025.03.15 测试脚本。
- 2025.03.16 固件测试完成，修改一些错误。固件测试通过，发布每周版。稳定版固件测试中。
- 2025.03.16 修改系统默认配置，语言、时区、NTP服务器等。定制版BusyBox,删除重复命令，~~新增常用命令~~。

## Credits

- [Microsoft Azure](https://azure.microsoft.com)
- [GitHub Actions](https://github.com/features/actions)
- [OpenWrt](https://github.com/openwrt/openwrt)
- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede)
- [Mikubill/transfer](https://github.com/Mikubill/transfer)
- [softprops/action-gh-release](https://github.com/softprops/action-gh-release)
- [Mattraks/delete-workflow-runs](https://github.com/Mattraks/delete-workflow-runs)
- [dev-drprasad/delete-older-releases](https://github.com/dev-drprasad/delete-older-releases)
- [peter-evans/repository-dispatch](https://github.com/peter-evans/repository-dispatch)
- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)

## License

[MIT](https://github.com/P3TERX/Actions-OpenWrt/blob/main/LICENSE) © [**P3TERX**](https://p3terx.com)