#!/bin/bash
# bash upgrade.sh -w (online/offline|must) -b (needback/noback|must) -v (pre/stable|must)
# R3S upgrade script
# curl -L -o /scripts/firstboot.sh https://raw.githubusercontent.com/yoier/r3s-firmware-build/main/files/scripts/firstboot.sh
# curl -L -o /scripts/upgrade.sh https://raw.githubusercontent.com/yoier/r3s-firmware-build/main/files/scripts/upgrade.sh
# curl -L -o /scripts/otherbackfs.txt https://raw.githubusercontent.com/yoier/r3s-firmware-build/main/files/scripts/otherbackfs.txt
# 20 5 1 * * /scripts/upgrade.sh -w online -b needback -p /tmp
# This script is powered by yoier
OTHER_BACK_FILE="/scripts/otherbackfs.txt"
upgrade_path="/tmp"

while [ $# -gt 0 ]; do
    case "$1" in
        -w|--way)
            upgrade_way="$2"
            echo "Update mode: $upgrade_way"
            shift 2
            ;;
        -b|--backup)
            backup_option="$2"
            echo "Backup options: $backup_option"
            shift 2
            ;;
        -v|--version)
            upgrade_version="$2"
            echo "Upgrade version: $upgrade_version"
            shift 2
            ;;
		-p|--path)
			if [[ "$2" == $upgrade_path ]]; then
				#mount -t tmpfs -o remount,size=1024m tmpfs $upgrade_path
                avail_kb=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
                if [ "$avail_kb" -gt $((896 * 1024)) ]; then
                    echo "free Mem OK"
                else
                    echo "free Mem so low"
                    exit 1
                fi
				echo "Upgrade path not specified, using default: $upgrade_path"
			else
                SET_PATH=1
				upgrade_path="$2"
                [ -d "$upgrade_path" ] || mkdir -p "$upgrade_path"
			fi
            echo "Upgrade path: $upgrade_path"
            shift 2
            ;;
        *)
            echo "Unknown parameters: $1,exit 1..."
            exit 1
            ;;
    esac
done

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

LOG_FILE="$upgrade_path/update_scr.log"

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
	rm -rf $upgrade_path/upg && mkdir $upgrade_path/upg && cd $upgrade_path/upg
	sha256numr=`curl -L ${durl}${tagname}/sha256sums | grep "img.gz" | awk '{print $1}'`
	if [[ $sha256numr == '' ]]; then loge "SHA256=null" red && exit 1; fi
	checkver
	curl -L -o r3s-ext4-sysupgrade.img.gz ${durl}${tagname}/openwrt-rockchip-armv8-friendlyarm_nanopi-r3s-ext4-sysupgrade.img.gz
	
}

function offline () {
	if [ ! -e $upgrade_path/upload/*.gz ] && [ ! -e $upgrade_path/upload/sha256su* ]; then loge "No update_files in $upgrade_path/upload/(*.gz,sha256sums)" red && exit 1; fi
	rm -rf $upgrade_path/upg && mkdir $upgrade_path/upg && cd $upgrade_path/upg
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
	mount -t ext4 $1 /mnt/img
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
    if [[ $SET_PATH == 1 ]]; then mv back.tar.gz $upgrade_path/backup_$(date +%Y%m%d_%H%M%S).tar.gz; fi
	# rm back.tar.gz
	cd $upgrade_path/upg
	wait_seds 3
	umount /mnt/img
}

# main
check_input() {
    echo "$2" | grep -qw "$1" && return 0
    loge "$1: Unknown parameters in: $2" red
    return 1
}
check_input $upgrade_way "online|offline" || exit 1
check_input $backup_option "needback|noback" || exit 1
loge "Wait 10 seconds before continuing" red
wait_seds 10

# bg
# if ! command -v resize2fs &> /dev/null; then loge "CMD_not_found! installing pkg" red
# 	apk update || true
# 	apk add fdisk sfdisk losetup resize2fs coreutils-truncate coreutils-dd
# 	if ! command -v resize2fs &> /dev/null; then loge "Installation failed,please check your network!" red && exit 1; else loge "Successful installation" green; fi
# fi

if [[ $upgrade_way == "online" ]]; then online $upgrade_version; else offline; fi
sha256numf=$(sha256sum r3s-ext4-sysupgrade.img.gz | awk '{print $1}')
if [[ $sha256numr != $sha256numf ]]; then loge "SHA256 verification failed!" red && exit 1; fi
loge "sha256 verification successful" green
#镜像文件名
IMG_NAME="FriendlyWrt.img"
mv r3s-ext4-sysupgrade.img.gz ${IMG_NAME}.gz
gzip -dvf ${IMG_NAME}.gz

##main
#当前ext4系统所在盘
DEV_NAME=$(lsblk -no PKNAME,MOUNTPOINT | awk '$2=="/"{print $1}')
loge "Current system disk: /dev/$DEV_NAME" blue
#DEV_NAME=$(lsblk -o NAME,TYPE | grep disk | awk '{print $1}')
#检测系统盘分区是否已完成分区
PART_COUNT=$(partx -g /dev/$DEV_NAME | wc -l)
loge "Current system disk partition count: $PART_COUNT" blue
DATA_LAB=$(lsblk -o LABEL /dev/$DEV_NAME | grep user_data)
loge "Current system disk user_data partition label: $DATA_LAB" blue
#当前系统盘逻辑扇区字节数(正常应为512，与镜像文件一致)
LBS=$(cat /sys/block/$DEV_NAME/queue/logical_block_size)
loge "Current system disk logical block size: $LBS" blue
#当前系统盘物理扇区字节数
#PBS=$(cat /sys/block/$DEV_NAME/queue/physical_block_size)
if [[ $PART_COUNT == "4" && $DATA_LAB == "user_data" ]]; then
    ROOTFS_START=$(partx -g -o START -n 2 /dev/$DEV_NAME)
    IMG_ROOTFS_START=$(partx -g -o START -n 2 $IMG_NAME)
    if [[ $ROOTFS_START == $IMG_ROOTFS_START ]]; then
        loge "rootfs partition start sector matches, can write" green
        ROOTFS_SIZE_MB=`expr $(partx -g -o SECTORS -n 2 /dev/$DEV_NAME) \* $LBS / 1024 / 1024`
        loge "rootfs partition start sector: $ROOTFS_START" blue
        ROOTFS_END=$(partx -g -o END -n 2 /dev/$DEV_NAME)
        ROOTFS_ALL_BYTE=$(expr \( $ROOTFS_END + 1 \) \* $LBS)
        ROOTFS_ALL_MB=$(expr $ROOTFS_ALL_BYTE / 1024 / 1024)
        truncate -s $ROOTFS_ALL_BYTE $IMG_NAME
        loge "rootfs partition end sector: $ROOTFS_END, partition size: $ROOTFS_SIZE_MB" blue
        #镜像rootfs扩容大小与设备rootfs分区一致
        #echo ",${ROOTFS_SIZE_MB}M" | sfdisk -N 2 $IMG_NAME
        echo ",+" | sfdisk -N 2 $IMG_NAME
        KERNEL_START_MB=`expr $(partx -g -o START -n 1 /dev/$DEV_NAME) \* $LBS / 1024 / 1024`
        IMG_KERNEL_START_MB=`expr $(partx -g -o START -n 1 $IMG_NAME) \* $LBS / 1024 / 1024`
        WIRTE_SIZE_MB=`expr $ROOTFS_ALL_MB - $KERNEL_START_MB`
        loge "write size: $WIRTE_SIZE_MB" blue
    else
        loge "rootfs partition start sector does not match, please check" red
        exit 1
    fi
    #普通更新

else
    #首次分区
    #自定义分区大小(单位MB)
    rootfs_size=2048; swap_size=1024
    #kernel=32M; user_data=free_space(剩余空间) 两者不可更改
    loge "First time partitioning,creating rootfs:${rootfs_size}M,swap:${swap_size}M" blue
    #对齐值(按扇区),dd写入时block=$PBS(慢)
    #ALIGN=`expr $PBS / $LBS`
    #对齐值(MB) 1024*1024=1048576,dd写入时block=1M(快)。相对按扇区写入，存储空间损耗不到1MB
    ALIGN=1048576
    #当前系统盘扇区数量
    DEV_SECTORS=$(cat /sys/block/$DEV_NAME/size)
    #当前系统盘总大小(byte)
    DEV_SIZE_BYTE_ALL=`expr $DEV_SECTORS \* $LBS`
    loge "Current system disk total size: $DEV_SIZE_BYTE_ALL" blue
    #------------
    #32MB字节数
    MB_32=`expr 32 \* 1024 \* 1024`
    #32MB扇区数
    MB_32_SECTORS=`expr $MB_32 / $LBS`
    #镜像文件大小对齐(byte)，末端预留约32MB
    ##向上对齐
    #IMG_SIZE_BYTE_ALL=$(( (DEV_SIZE_BYTE_ALL - $MB_32 + ($ALIGN - 1)) / $ALIGN * $ALIGN ))
    ##向下对齐
    IMG_SIZE_BYTE_ALL=$(( (DEV_SIZE_BYTE_ALL - $MB_32) / $ALIGN * $ALIGN ))
    loge "Image file size after alignment: $IMG_SIZE_BYTE_ALL" blue
    #扩展镜像文件大小(byte)
    truncate -s $IMG_SIZE_BYTE_ALL $IMG_NAME
    sync
    #扩展镜像第二分区(rootfs)大小
    loge "set rootfs partition size: ${rootfs_size}M" blue
    echo ",${rootfs_size}M" | sfdisk -N 2 $IMG_NAME
    sync
    #新建第三分区user_data(剩余空间-swap_size)
    ##第三分区起始扇区
    IMG_THIRD_PART_START=`expr $(partx -g -o END -n 2 $IMG_NAME) + $MB_32_SECTORS + 1`
    ##第三分区扇区大小
    IMG_THIRD_PART_SIZE=`expr \( $IMG_SIZE_BYTE_ALL - $swap_size \* 1024 \* 1024 - $MB_32 \) / $LBS - $IMG_THIRD_PART_START`
    loge "Third partition start sector: $IMG_THIRD_PART_START, size: $IMG_THIRD_PART_SIZE" blue
    ##设置第三分区大小(剩余空间-swap_size)
    loge "set user_data partition size: $IMG_THIRD_PART_SIZE" blue
    echo "$IMG_THIRD_PART_START,$IMG_THIRD_PART_SIZE,83" | sfdisk -a $IMG_NAME
    sync
    #新建第四分区swap(swap_size)
    ##第四分区起始扇区
    IMG_FOURTH_PART_START=`expr $(partx -g -o END -n 3 $IMG_NAME) + $MB_32_SECTORS + 1`
    loge "Fourth partition start sector: $IMG_FOURTH_PART_START" blue
    ##设置第四分区大小(swap_size)
    loge "set swap partition size: ${swap_size}M" blue
    echo "$IMG_FOURTH_PART_START,+,82" | sfdisk -a $IMG_NAME
    sync
    FLG=1
fi
loge "Packing" blue
# 映射分区成块设备
IMG_LOOP=$(losetup --find --show -P $IMG_NAME)
loge "Mapped image file to loop device: $IMG_LOOP" blue
# 检查分区并修复
# partprobe
# udevadm settle
loge "Checking and repairing rootfs partition" blue
e2fsck -yf $IMG_LOOP"p2"
sync
# 扩展文件系统
loge "Resizing rootfs partition" blue
resize2fs $IMG_LOOP"p2"
sync
e2fsck -yf $IMG_LOOP"p2"
sync
if [[ $FLG == "1" ]]; then
    loge "First time partitioning,creating user_data and swap partitions" blue
    # 初始化SWAP分区和user_data分区
    loge "Creating ext4 filesystem for user_data partition" blue
    mkfs.ext4 -L user_data $IMG_LOOP"p3"
    sync
    loge "Creating swap filesystem for swap partition" blue
    mkswap -L swap $IMG_LOOP"p4"
    sync
fi
# 修改文件镜像文件内容
loge "Modifying image file content" blue
if [[ $backup_option == "needback" ]]; then isbackup $IMG_LOOP"p2"; fi
sync
wait_seds 5
# 用完卸载
if cat /proc/mounts | grep -q $IMG_LOOP"p2"; then umount $IMG_LOOP"p2"; fi
losetup -d $IMG_LOOP
sync
# 写入块设备
loge "After 10s will writing..." red
wait_seds 10
if [ -f $IMG_NAME ]; then
	echo 1 > /proc/sys/kernel/sysrq
	echo u > /proc/sysrq-trigger && umount / || true
    if [[ $FLG == "1" ]]; then
        #首次分区写入全部分区，包含分区表
        loge "First time partitioning,writing all partitions" blue
        dd if=$IMG_NAME of=/dev/$DEV_NAME oflag=direct status=progress bs=1M conv=sparse
    else
        #普通更新只写入rootfs分区
        loge "Writing rootfs partition only" blue
        dd if=$IMG_NAME of=/dev/$DEV_NAME oflag=direct status=progress bs=1M seek=$KERNEL_START_MB skip=$IMG_KERNEL_START_MB count=$WIRTE_SIZE_MB conv=sparse
    fi
    sync
	loge 'writed successfully!, wait reboot' green
	echo b > /proc/sysrq-trigger
fi
#--------------------------------------------
# echo 1 > /proc/sys/kernel/sysrq
# echo u > /proc/sysrq-trigger && umount / || true
# dd if=/tmp/upg/upg.img of=/dev/mmcblk0 oflag=direct status=progress bs=1M seek=32 skip=32 count=1056 conv=sparse
# sync
# echo b > /proc/sysrq-trigger

# dd if=1upg.img of=/dev/sdb oflag=direct conv=sparse status=progress bs=1M