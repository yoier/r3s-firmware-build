# Script to run on first boot after update.Similar to uci-defaults/, but can be retained
sed -i '/passwall2\|passpackages\|kenzo/d' /etc/apk/repositories.d/distfeeds.list