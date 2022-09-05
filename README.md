# <center>LOG ROTATION AND BACKUP 🚀️
## <center>Log Rotation

To start log rotation (log file archiving/deletion when rotating conditions are met) you need to create the configuration file. Place following text to `/etc/logrotate.d/rclone.conf` (don't forget to specify a path to the log):

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

To specify log rotation check-time create `/etc/cron.d/logrotate` with the following content:<br>
`0  4  *  *  *   root    /usr/sbin/logrotate /etc/logrotate.conf` <br>
Log rotation checkup will run every day at 4:00. Note: this cronjob should run as root.

## <center> Log Backup

To automatically log backup use sh script `archive_logs.sh` (don't forget to specify a storage account and container for the archive) with following content:

`rclone copy "$(pwd)"/log/rclone/ --include=*.gz  $STORAGE:/$ARCHIVE_CONTAINER --azureblob-access-tier archive --ignore-existing`

`01 4 * * * username  /bin/bash  ~/archive_logs.sh`

Options above may vary, and we’ll know the exact values after Truven-machine allocation and the use-case statistic collection.
