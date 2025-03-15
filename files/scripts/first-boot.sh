# Script to run on first boot after update.
sed -i '/passwall2\|passpackages\|kenzo/d' /etc/apk/repositories.d/distfeeds.list
