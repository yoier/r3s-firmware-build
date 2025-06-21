#!/bin/bash
# bash upgrade.sh (online/offline|must) (needback/noback|must)
# R3S upgrade scr
# curl -L -o /scripts/firstboot.sh https://raw.githubusercontent.com/yoier/r3s-firmware-build/main/files/scripts/firstboot.sh
# curl -L -o /scripts/upgrade.sh https://raw.githubusercontent.com/yoier/r3s-firmware-build/main/files/scripts/upgrade.sh
# curl -L -o /scripts/otherbackfs.txt https://raw.githubusercontent.com/yoier/r3s-firmware-build/main/files/scripts/otherbackfs.txt
# 20 5 * * 1 /scripts/upgrade.sh online needback
# This script is powered by yoier
LOG_FILE="/tmp/update_scr.log"
OTHER_BACK_FILE="/scripts/otherbackfs.txt"

function loge () {
# red 1;blue 2;green 3
	case $2 in
		red)
			color='\e[91m'
			;;
		blue)
			color='\e[94m'
			;;
		*)
			color='\e[92m'
			;;
	esac
	echo -e ${color}"$1\e[0m"
	echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

function wait_seds() {
	local seconds="$1"
	for ((i = seconds; i >= 1; i--)); do
		echo -ne "\e[92m\rWait $i s...\e[0m"
		sleep 1
	done
		echo "Over"
}

function checkver () {
	# thisver.sha
	thisver=$(cat /thisver.sha)
	if [[ $thisver == $sha256numr ]]; then loge "No update package" blue && exit 0; fi
}

function online () {
	durl="https://github.com/yoier/r3s-firmware-build/releases/download/"
	if [[ $1 == "pre" ]]; then
		loge "Install Prerelease!!!" red
		tagname=$(curl -s "https://api.github.com/repos/yoier/r3s-firmware-build/releases" | jq -r '.[] | select(.prerelease == true) | .tag_name' | head -n 1)
	else
		loge "Install Stable Ver" blue
		tagname=`curl -L https://api.github.com/repos/yoier/r3s-firmware-build/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'`
	fi
	if [[ $tagname == '' ]]; then loge "Check your network" red && exit 1; fi
	mount -t tmpfs -o remount,size=850m tmpfs /tmp
	rm -rf /tmp/upg && mkdir /tmp/upg && cd /tmp/upg
	sha256numr=`curl -L ${durl}${tagname}/sha256sums | grep "img.gz" | awk '{print $1}'`
	if [[ $sha256numr == '' ]]; then loge "SHA256=null" red && exit 1; fi
	checkver
	curl -L -o r3s-ext4-sysupgrade.img.gz ${durl}${tagname}/openwrt-rockchip-armv8-friendlyarm_nanopi-r3s-ext4-sysupgrade.img.gz
	
}

function offline () {
	if [ ! -e /tmp/upload/*.gz ] && [ ! -e /tmp/upload/sha256su* ]; then loge "No update_files in /tmp/upload/(*.gz,sha256sums)" red && exit 1; fi
	mount -t tmpfs -o remount,size=850m tmpfs /tmp
	rm -rf /tmp/upg && mkdir /tmp/upg && cd /tmp/upg
	mv /tmp/upload/* /tmp/upg
	sha256numr=`cat sha256su* | grep "img.gz" | awk '{print $1}'`
	if [[ $sha256numr == '' ]]; then loge "sha256=null" red && exit 1; fi
	checkver
}

function otherback () { 
	for file in $(cat $OTHER_BACK_FILE); do
		if [ -f "$file" ]; then
			local dirn=$(dirname $file)
			mkdir -p $1$dirn
			cp -p $file $1$dirn
			loge "Copy file $file to $1$dirn" blue
			
		elif [ -d "$file" ]; then
			local dirn=$(dirname $file)
			mkdir -p $1$dirn
			cp -rp $file $1$dirn
			loge "Copy dir $file to $1$dirn" blue
		else
			loge "Err file or dir: $file" red
		fi
	done
	loge "Copy success" green
}

function isbackup () {
	mkdir -p /mnt/img
	mount -t ext4 ${lodev} /mnt/img
	loge "Backing up" blue
	wait_seds 10
	cd /mnt/img
	rm etc/uci-defaults/* # Delete the script for the first installation startup (it should not be run when subsequent updates are started, but only run the script generated after the backup)
	sysupgrade -b back.tar.gz
	tar -zxf back.tar.gz
	wait_seds 5
	cat > localexr.tmp << EOF
bash /scripts/firstboot.sh
sed -i '1,3d' /etc/rc.local
EOF
	wait_seds 1
	sed -i '1i # firstCMD' /mnt/img/etc/rc.local
	wait_seds 1
	sed -i '1r localexr.tmp' /mnt/img/etc/rc.local
	wait_seds 1
	rm localexr.tmp
	echo $sha256numr > thisver.sha
	otherback /mnt/img
	loge "Restoring backup completed,umount" green
	# rm back.tar.gz
	cd /tmp/upg
	wait_seds 3
	umount /mnt/img
}

# main
case "$1" in
	online|offline)
		loge "Update mode: $1" blue
		;;
	*)
		loge "Unknown parameters: $1,exit 1..."
		exit 1
		;;
esac
case "$2" in
	needback|noback)
		loge "Backup options: $2" blue
		;;
	*)
		loge "Unknown parameters: $2,exit 1..."
		exit 1
		;;
esac
case "$3" in
	pre|stable)
		loge "Backup options: $3" blue
		;;
	*)
		loge "Unknown parameters: $3,exit 1..."
		exit 1
		;;
esac
loge "Wait 10 seconds before continuing" red
wait_seds 10

# bg
# if ! command -v resize2fs &> /dev/null; then loge "CMD_not_found! installing pkg" red
# 	apk update || true
# 	apk add fdisk sfdisk losetup resize2fs coreutils-truncate coreutils-dd
# 	if ! command -v resize2fs &> /dev/null; then loge "Installation failed,please check your network!" red && exit 1; else loge "Successful installation" green; fi
# fi

if [[ $1 == "online" ]]; then online $3; else offline; fi

sha256numf=$(sha256sum *.gz | awk '{print $1}')
if [[ $sha256numr != $sha256numf ]]; then loge "SHA256 verification failed!" red && exit 1; fi
loge "sha256 verification successful" green

mv *.gz FriendlyWrt.img.gz
gzip -dv *.gz
block_device=`lsblk -no PKNAME /dev/$(lsblk -o NAME,MOUNTPOINT | awk '$2 == "/" {print $1}' | sed 's/^[│└─ ]*//')`
bs=`expr $(cat /sys/block/$block_device/size) \* 512`
truncate -s $bs FriendlyWrt.img || ../truncate -s $bs FriendlyWrt.img
echo ", +" | sfdisk -N 2 FriendlyWrt.img
loge "Packing" blue
lodev=$(losetup -f)
losetup -o 100663296 $lodev FriendlyWrt.img
if [[ $2 == "needback" ]]; then isbackup; fi
wait_seds 5
if cat /proc/mounts | grep -q ${lodev}; then umount ${lodev}; fi
e2fsck -yf ${lodev} || true
resize2fs ${lodev}
losetup -d $lodev

loge "writing..." blue
if [ -f FriendlyWrt.img ]; then
	echo 1 > /proc/sys/kernel/sysrq
	echo u > /proc/sysrq-trigger && umount / || true
	dd if=FriendlyWrt.img of=/dev/$block_device oflag=direct conv=sparse status=progress bs=1M
	echo -e '\e[92mwrited,wait reboot\e[0m'
	echo b > /proc/sysrq-trigger
fi
