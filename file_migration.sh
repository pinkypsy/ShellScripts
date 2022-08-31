#!/bin/bash
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
echo ">Destination: $DESTINATION_PATH"

rclone ls "$DESTINATION_PATH" --error-on-no-transfer
if [ $? -ne 3 ]; then
  read -r -p "Would you like to replace files in the destination if files with the same name are detected? [y/n] " RESPONSE
  case "$RESPONSE" in
  [Nn]) IS_IGNORE_EXISTING=--ignore-existing ;;
  esac
else
  echo ">${DESTINATION_PATH}: directory with such name not found. Creating..."
fi

rclone copy -v "$SOURCE_PATH" "$DESTINATION_PATH" \
  $IS_IGNORE_EXISTING --transfers $COUNT --checkers $COUNT \
  --azureblob-disable-checksum --stats 10s --stats-file-name-length 0 \
  --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 \
  --azureblob-memory-pool-flush-time 60s --azureblob-upload-concurrency 256 \
  --azureblob-chunk-size 32M --azureblob-memory-pool-use-mmap \
  --error-on-no-transfer

EXIT_CODE=$?
echo "Exit code: $EXIT_CODE"

if [ $EXIT_CODE -eq 0 ]; then
  echo "Operation successful"
elif [ $EXIT_CODE -eq 1 ]; then
  echo "Syntax or usage error"
elif [ $EXIT_CODE -eq 2 ]; then
  echo "Error not otherwise categorised"
elif [ $EXIT_CODE -eq 3 ]; then
  echo "Directory not found"
elif [ $EXIT_CODE -eq 4 ]; then
  echo "File not found"
elif [ $EXIT_CODE -eq 5 ]; then
  echo "Temporary error (one that more retries might fix) (Retry errors)"
elif [ $EXIT_CODE -eq 6 ]; then
  echo "Less serious errors (NoRetry errors)"
elif [ $EXIT_CODE -eq 7 ]; then
  echo "Fatal error (one that more retries won't fix, like account suspended)"
elif [ $EXIT_CODE -eq 8 ]; then
  echo "Transfer exceeded - limit set by --max-transfer reached"
elif [ $EXIT_CODE -eq 9 ]; then
  echo "Operation successful, but no files transferred"
fi

#for access logs  --azureblob-access-tier archive
