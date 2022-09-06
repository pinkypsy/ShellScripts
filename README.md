# <center>LOG ROTATION AND BACKUP 🚀️

## <center>Log Rotation

To start log rotation (log file archiving/deletion when rotating conditions are met) you need to create the configuration file. Place the following text to `/etc/logrotate.d/rclone.conf` file (don't forget to specify a path to the log):

```
/path/to/log/rclone/access.log {
daily
rotate 16
size 1M
create
compress
notifempty
dateext
dateformat -%m%d%Y-%H%M
}
```

The above configuration tracks a log file `/log/rclone/access.log`
and rotates it daily or on 1MB log size reaching.<br>
After the log file archiving, it creates an empty log file. Archive creation date and time appends to the archive name with the specified format.<br>
A log file isn’t rotated if it’s empty.
It stores up to 16 archive files before deletion.
<br>
See more information about log rotation [here](https://linux.die.net/man/8/logrotate).

To specify log rotation check-time create `/etc/cron.d/logrotate` file with the following content:<br>
`0  4  *  *  *   root    /usr/sbin/logrotate /etc/logrotate.conf` <br>
Log rotation checkup will run every day at 4:00. Note: this cronjob should run as root.
<hr>

## <center> Log Backup

To automate the log backup process use script `archive_logs.sh` (don't forget to specify a storage account and container for the archive) with the following content:<br>
`rclone copy "$(pwd)"/log/rclone/ --include=*.gz  $STORAGE:/$ARCHIVE_CONTAINER --azureblob-access-tier archive --ignore-existing`

This script will force the rclone to copy log archives to the remote storage account with the archive access tier.

To automatically execute this script place the following line to the `/etc/crontab` file (specify a username, time and path to script):

`01 4 * * * username  /bin/bash  ~/archive_logs.sh`

This cronjob will force `/archive_logs.sh` script execution daily at 4:01.
<br>

**N.B. Options above may vary, and we’ll know the exact values after Truven-machine allocation and the use-case statistic collection.**
