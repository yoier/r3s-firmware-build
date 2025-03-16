# Script to run on first boot after update.Similar to uci-defaults/, but can be retained
# This script is powered by yoier
sed -i '/passwall2\|passpackages\|kenzo/d' /etc/apk/repositories.d/distfeeds.list