#!/bin/bash

LOG_PATH="$(pwd)/log/rclone"
LOG_FILE="$LOG_PATH/access.log"
TEMP_LOG_FILE="temp_rclone.log"

DESTINATION=  #!!!!!!specify archive storage account (pattern: STORAGE_ACCOUNT_NAME:/CONTAINER_NAME/destination/path): "

NEWLINE_CHAR=$'\n'

LOG_TEXT="<START OF TRANSACTION**********************************************************************
Datetime=$(date);User=$(whoami);Action=BACKUP;Source=$LOG_FILE;Destination=$DESTINATION
Description=Executing backup to remote storage account $DESTINATION $NEWLINE_CHAR"

echo "$LOG_TEXT" >>"$LOG_FILE"

rclone copy -v $LOG_PATH --include=*.gz $DESTINATION --azureblob-access-tier archive \
  --ignore-existing --error-on-no-transfer --log-file $TEMP_LOG_FILE

LIST_OF_COPIED_ITEMS=$(grep -P '(INFO  : ).*(: Copied)' $TEMP_LOG_FILE)
echo "$LIST_OF_COPIED_ITEMS $NEWLINE_CHAR" >> "$LOG_FILE"

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  EXIT_DESCRIPTION="Successfully $(grep -P '(Transferred:).*[[:digit:]](?=,)' $TEMP_LOG_FILE) archived logs"
elif [ $EXIT_CODE -eq 9 ]; then
  EXIT_DESCRIPTION="Operation successful, but no files transferred (files in the source and destination are similar)"
else
  EXIT_DESCRIPTION="Backup process failed"
fi

LOG_TEXT="Datetime=$(date);User=$(whoami);Action=BACKUP;Source=$LOG_FILE;Destination=$DESTINATION
Description=$EXIT_DESCRIPTION
************************************************************************END OF TRANSACTION> $NEWLINE_CHAR $NEWLINE_CHAR"
echo "$LOG_TEXT" >>"$LOG_FILE"

rm $TEMP_LOG_FILE