#!/bin/bash
# Default config file
config_file="./config/config.conf"

# Check if --cfg parameter is provided
while [[ $# -gt 0 ]]; do
    case $1 in
        --cfg)
            shift
            config_file="$1"
            ;;
        *)
            # Ignore other options for now
            ;;
    esac
    shift
done
source $config_file
# remove the result.csv if exists
rm cf_ddns/result.csv

case $DNS_PROVIDER in
    1)
        source ./cf_ddns/cf_ddns_cloudflare.sh
        ;;
    *)
        echo "未选择任何DNS服务商"
        ;;
esac

# informlog中不能带空格，否则不能被识别
# source ./cf_ddns/cf_push.sh

exit 0;
