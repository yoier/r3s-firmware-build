# Script to run on first boot after update.Similar to uci-defaults/, but can be retained
# This script is powered by yoier
sed -i '/passwall2\|passwall_packages\|kenzo\|openwrtdaede\|vmlinuxbtf/d' /etc/apk/repositories.d/distfeeds.list
ln -s /usr/share/v2ray/geosite.dat /usr/share/daed/geosite.dat
ln -s /usr/share/v2ray/geoip.dat /usr/share/daed/geoip.dat