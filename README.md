sudo vim /etc/logrotate.d/rclone.conf

/var/log/rclone/access.log {
daily
rotate 16
size 1M
create
compress
missingok
notifempty
dateext
dateformat -%m%d%Y-%H%M
}