#!/bin/bash

LOG_PATH="$(pwd)/log/rclone"
LOG_FILE="$LOG_PATH/access.log"
mkdir -p "$LOG_PATH" && touch "$LOG_FILE"

NEWLINE_CHAR=$'\n'

TEMP_LOG_FILE="temp_rclone.log"

if [ -z "$SOURCE_PATH" ]; then
  read -r -p "Enter source path to the file or directory: " SOURCE_PATH
fi
echo ">Source: $SOURCE_PATH"

if [ -d "${SOURCE_PATH}" ]; then
  COUNT=$(find "$SOURCE_PATH" -type f | wc -l)
elif [ -f "${SOURCE_PATH}" ]; then
  COUNT=1
else
  echo ">${SOURCE_PATH}: file or directory with such name not found"
  exit 1
fi
echo ">Number of files to copy: $COUNT"

if [ -z "$DESTINATION_PATH" ]; then
  read -r -p "Enter destination path (pattern: STORAGE_ACCOUNT_NAME:/CONTAINER_NAME/destination/path): " DESTINATION_PATH
fi
echo ">Destination: $DESTINATION_PATH content"

rclone lsl "$DESTINATION_PATH" --error-on-no-transfer
if [ $? -ne 3 ]; then
  read -r -p "Would you like to replace files in the destination if files with the same name (but different content) are detected? [y/n] " RESPONSE
  case "$RESPONSE" in
  [Nn]) IS_IGNORE_EXISTING=--ignore-existing ;;
  esac
else
  echo ">${DESTINATION_PATH}: directory with such name not found. Creating..."
fi

LOG_TEXT="<START OF TRANSACTION**********************************************************************
Datetime=$(date);User=$(whoami);Action=COPY;Source=$SOURCE_PATH;Destination=$DESTINATION_PATH
Description=$USER have initiated copying of $COUNT file(s) to the $DESTINATION_PATH $NEWLINE_CHAR"

echo "$LOG_TEXT" >> "$LOG_FILE"

rclone copy -v "$SOURCE_PATH" "$DESTINATION_PATH" \
  $IS_IGNORE_EXISTING --transfers $COUNT \
  --azureblob-disable-checksum --stats 10s --stats-file-name-length 0 \
  --azureblob-memory-pool-flush-time 60s --azureblob-upload-concurrency 128 \
  --azureblob-chunk-size 32M --azureblob-memory-pool-use-mmap \
  --error-on-no-transfer --log-file $TEMP_LOG_FILE -P

EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  EXIT_DESCRIPTION="Successfully $(grep -P '(Transferred:).*[[:digit:]](?=,)' $TEMP_LOG_FILE)"
elif [ $EXIT_CODE -eq 1 ]; then
  EXIT_DESCRIPTION="Syntax or usage error"
elif [ $EXIT_CODE -eq 2 ]; then
  EXIT_DESCRIPTION="Error not otherwise categorised"
elif [ $EXIT_CODE -eq 3 ]; then
  EXIT_DESCRIPTION="Directory not found"
elif [ $EXIT_CODE -eq 4 ]; then
  EXIT_DESCRIPTION="File not found"
elif [ $EXIT_CODE -eq 5 ]; then
  EXIT_DESCRIPTION="Temporary error (one that more retries might fix) (Retry errors)"
elif [ $EXIT_CODE -eq 6 ]; then
  EXIT_DESCRIPTION="Less serious errors (NoRetry errors)"
elif [ $EXIT_CODE -eq 7 ]; then
  EXIT_DESCRIPTION="Fatal error (one that more retries won't fix, like account suspended)"
elif [ $EXIT_CODE -eq 8 ]; then
  EXIT_DESCRIPTION="Transfer exceeded specified limit"
elif [ $EXIT_CODE -eq 9 ]; then
  EXIT_DESCRIPTION="Operation successful, but no files transferred (files in the source and destination are similar)"
elif [ $EXIT_CODE -eq 137 ]; then
  EXIT_DESCRIPTION="Out of memory"
else
  EXIT_DESCRIPTION="Unknown code. Please check result manually"
fi

echo "Exit code: $EXIT_CODE"
echo "$EXIT_DESCRIPTION"

LOG_TEXT="Datetime=$(date);User=$(whoami);Action=COPY;Source=$SOURCE_PATH;Destination=$DESTINATION_PATH
Description=$EXIT_DESCRIPTION
************************************************************************END OF TRANSACTION> $NEWLINE_CHAR $NEWLINE_CHAR"
echo "$LOG_TEXT" >> "$LOG_FILE"

rm $TEMP_LOG_FILE