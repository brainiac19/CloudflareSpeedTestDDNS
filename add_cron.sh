#!/bin/bash
if [ -z "$CRON" ]; then
    echo "CRON environment variable not set"
    exit 1
fi

COMMAND="/bin/bash start.sh"
TEMP_FILE=$(mktemp)
echo "$CRON $COMMAND" > "$TEMP_FILE"
crontab "$TEMP_FILE"
rm "$TEMP_FILE"