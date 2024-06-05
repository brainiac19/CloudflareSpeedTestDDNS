#!/bin/sh
# Define the command to be scheduled
COMMAND="/bin/sh /app/start.sh"

# Check if CRON environment variable is set
if [ -z "$CRON" ]; then
    echo "CRON environment variable not set, running once..."
    eval "$COMMAND"
fi


# Create a temporary file for the cron job
TEMP_FILE=$(mktemp)

# Add the cron schedule and command to the temp file
echo "$CRON $COMMAND" > "$TEMP_FILE"

# Install the new cron job from the temp file
crontab "$TEMP_FILE"

# Remove the temporary file
rm "$TEMP_FILE"

# Start the cron daemon in the foreground
exec crond -f -l 2
