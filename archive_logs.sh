LOG_FILE="$(pwd)/log/rclone/access.log"
TEMP_LOG_FILE="temp_rclone.log"

ARCHIVE_STORAGE=   #specify archive storage account
ARCHIVE_CONTAINER= #specify archive container

LOG_TEXT="<START OF TRANSACTION**********************************************************************
Datetime=$(date);User=$USER;Action=Backup;Source=$LOG_FILE;Destination=$ARCHIVE_STORAGE:/$ARCHIVE_CONTAINER
Description=Executing backup to remote storage account $ARCHIVE_STORAGE:/$ARCHIVE_CONTAINER \n"

echo "$LOG_TEXT" >>"$LOG_FILE"

rclone copy -v "$(pwd)"/log/rclone/ --include=*.gz "$ARCHIVE_STORAGE":/archive --azureblob-access-tier archive \
  --ignore-existing --error-on-no-transfer --log-file $TEMP_LOG_FILE

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  EXIT_DESCRIPTION="Successfully $(grep -P '(Transferred:).*[[:digit:]](?=,)' $TEMP_LOG_FILE)"
elif [ $EXIT_CODE -eq 9 ]; then
  EXIT_DESCRIPTION="Operation successful, but no files transferred (files in the source and destination are similar)"
else
  EXIT_DESCRIPTION="Backup process failed"
fi

LOG_TEXT="Datetime=$(date);User=$USER;Action=Backup;Source=$LOG_FILE;Destination=$DESTINATION_PATH
Description=$EXIT_DESCRIPTION
************************************************************************END OF TRANSACTION> \n\n"
echo "$LOG_TEXT" >>"$LOG_FILE"

rm $TEMP_LOG_FILE
