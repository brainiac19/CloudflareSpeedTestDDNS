#!/bin/bash
# Define the command to be scheduled
cd /app || exit
CRONTAB="/etc/crontabs/root"
echo "Starting entrypoint script..."
ln -s ./start.sh ./start
rm -rf $CRONTAB

# Check if CRON environment variable is set

echo "Setting up cron jobs..."
env >>/etc/environment

while IFS='=' read -r -d '' n v; do
    if [[ "$n" =~ ^CRON ]]; then
        echo -e "$n >/proc/1/fd/1 2>/proc/1/fd/2" >>"$CRONTAB"
    fi
done < <(env -0)

if [[ -f "$CRONTAB" ]]; then
    chown "root:root" "$CRONTAB"
    chmod 0600 "$CRONTAB"
    "$@"
else
    log "CRON not set, running once..."
    start
fi
