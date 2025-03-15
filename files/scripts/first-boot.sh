# Script to run on first boot after update.
ln -s /etc/init.d/fa-rk3328-pwmfan /etc/rc.d/S96fa-rk3328-pwmfan
service fa-rk3328-pwmfan start
sed -i '/passwall2\|passpackages\|kenzo/d' /etc/apk/repositories.d/distfeeds.list
