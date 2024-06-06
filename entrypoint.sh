#!/bin/bash
# Define the command to be scheduled
COMMAND="cd /app && /bin/bash /app/start.sh"

# Logging
echo "Starting entrypoint script..."
echo "COMMAND: $COMMAND"

# Check if CRON environment variable is set
if [ -z "$CRON" ]; then
    echo "CRON environment variable not set, running once..."
    $COMMAND
else
    echo "CRON environment variable is set to '$CRON'"
    env >> /etc/environment
    CRONTAB="/etc/crontabs/root"
    echo -e "$CRON $COMMAND >/proc/1/fd/1 2>/proc/1/fd/2" > "$CRONTAB"
    chown "root:root" "$CRONTAB"
    chmod 0600 "$CRONTAB"
    ls -al "$CRONTAB"
    "$@"
fi
