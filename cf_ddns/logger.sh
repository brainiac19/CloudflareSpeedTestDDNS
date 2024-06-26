#!/bin/bash




get_log_file_size() {
    if [ -e "$LOG_FILE" ]; then
        stat -c%s "$LOG_FILE"
    else
        echo 0
    fi
}

CURRENT_LOG_SIZE=$(get_log_file_size)

rotate_logs() {
    local log_file="$1"

    for ((i=MAX_FILES-1; i>=0; i--)); do
        if [ -e "${log_file}.${i}" ]; then
            mv "${log_file}.${i}" "${log_file}.$((i+1))"
        fi
    done

    if [ -e "$log_file" ]; then
        mv "$log_file" "${log_file}.0"
    fi

    CURRENT_LOG_SIZE=0
}

log() {
    local message="$*"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')

    if [ "$DEBUG" -eq 1 ]; then
        local caller_info=$(caller 0)
        local log_entry="$timestamp - $message - $caller_info"
    else
        local log_entry="$timestamp - $message"
    fi

    local log_entry_size=${#log_entry}

    CURRENT_LOG_SIZE=$((CURRENT_LOG_SIZE + log_entry_size + 1))

    if [ $CURRENT_LOG_SIZE -ge $MAX_LOG_SIZE ]; then
        rotate_logs "$LOG_FILE"
    fi

    echo "$log_entry" >> "$LOG_FILE"
}

parseSeconds() {
    local runtime=$1
    local hours=$((runtime / 3600))
    local minutes=$(( (runtime % 3600) / 60 ))
    local seconds=$((runtime % 60))

    # Construct the formatted time string
    local time_str=""
    if [ $hours -gt 0 ]; then
        time_str="${hours}时${minutes}分${seconds}秒"
    elif [ $minutes -gt 0 ]; then
        time_str="${minutes}分${seconds}秒"
    else
        time_str="${seconds}秒"
    fi

    echo "$time_str"
}