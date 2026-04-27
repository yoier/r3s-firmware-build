# Script to run on first boot after update.Similar to uci-defaults/, but can be retained
# This script is powered by yoier
sed -i '/passwall2\|passwall_packages\|kenzo/d' /etc/apk/repositories.d/distfeeds.list