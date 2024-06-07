#!/bin/bash
# Default config file
cd /app
source ./volume/config.conf
source ./cf_ddns/logger.sh
LOCKFILE="/tmp/start.lock"

cleanup() {
    rm -f "$LOCKFILE"
}

trap cleanup EXIT HUP INT QUIT TERM

[[ -e "$LOCKFILE" && -e /proc/$(cat "$LOCKFILE") ]] && exit 1 || rm -f "$LOCKFILE"

echo $$ > "$LOCKFILE"

log "===================CFSTDDNS 运行开始====================="
source ./cf_ddns/init.sh

rm -rf ./cf_ddns/informlog

while [[ $# -gt 0 ]]; do
    case $1 in
    -ip | --ip_family)
        shift
        IP_FAMILY="$1"
        ;;
    -st | --speed_test_only)
        SPEED_TEST_ONLY=1
        ;;
    -ddns | --ddns_only)
        DDNS_ONLY=1
        ;;
    *)
        log "不支持的选项: $1"
        exit 1
        ;;
    esac
    shift
done

if [[ -z "$DDNS_ONLY" ]]; then
    source ./cf_ddns/cf_speedtest.sh
fi

if [[ -z "$SPEED_TEST_ONLY" ]]; then
    for DNS_PROVIDER in "${DNS_PROVIDERS[@]}"; do
        case $DNS_PROVIDER in
        cloudflare)
            source ./cf_ddns/cf_ddns_cloudflare.sh
            ;;
        *)
            log "不支持的DNS服务商: $DNS_PROVIDER"
            ;;
        esac
    done
fi
log "===================CFSTDDNS 运行结束====================="
# informlog中不能带空格，否则不能被识别
# source ./cf_ddns/cf_push.sh

