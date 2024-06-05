#!/bin/bash
# Define the command to be scheduled
COMMAND="/bin/bash /app/start.sh"

# Check if CRON environment variable is set
if [ -z "$CRON" ]; then
    echo "CRON environment variable not set, running once..."
    $COMMAND
else
    TEMP_FILE=$(mktemp)
    echo "$CRON $COMMAND" > "$TEMP_FILE"
    crontab "$TEMP_FILE"
    rm "$TEMP_FILE"
    exec crond -f -l 2
fi


