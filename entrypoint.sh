#!/bin/bash
# Define the command to be scheduled

echo "Starting entrypoint script..."
cd /app || exit
rm -rf "$CRONTAB"

# Check if CRON environment variable is set

echo "Setting up cron jobs..."
env >>/etc/environment

CRONTAB="/etc/crontabs/root"
while IFS='=' read -r -d '' n v; do
    if [[ "$n" =~ ^CRON ]]; then
        echo "$(echo "$v" | sed 's|start|cd /app \&\& /bin/bash /app/start.sh|') >/proc/1/fd/1 2>/proc/1/fd/2">>"$CRONTAB"
    fi
done < <(env -0)

if [[ -f "$CRONTAB" ]]; then
    chown "root:root" "$CRONTAB"
    chmod 0600 "$CRONTAB"
    "$@"
else
    log "CRON not set, running once..."
    /bin/bash /app/start.sh
fi
