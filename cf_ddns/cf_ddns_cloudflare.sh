#!/bin/bash
#		版本：20231004
#         用于CloudflareST调用，更新hosts和更新cloudflare DNS。

#判断是否配置测速地址
if [[ "$CFST_URL" == http* ]]; then
  CFST_URL_R="-url $CFST_URL -tp $CFST_TP "
else
  CFST_URL_R=""
fi

# 检查 cfcolo 变量是否为空
if [[ -n "$cfcolo" ]]; then
  cfcolo="-cfcolo $cfcolo"
fi

# 检查 httping_code 变量是否为空
if [[ -n "$httping_code" ]]; then
  httping_code="-httping-code $httping_code"
fi

# 检查 CFST_STM 变量是否为空
if [[ -n "$CFST_STM" ]]; then
  CFST_STM="-httping $httping_code $cfcolo"
fi

# 检查是否配置反代IP
if [ "$IP_PR_IP" = "1" ]; then
  curl -sSf -o ./cf_ddns/pr_ip.txt "$CFIP_URL"
  log "已更新反向代理列表"
else
  rm -f ./cf_ddns/pr_ip.txt
fi

loadIPs() {
  local csv_file=$1
  local count=${2:-3}

  local ips=()
  local current_line=-1
  local ip_counter=0

  while read -r line; do
    current_line=$((current_line + 1))
    if [[ $current_line -eq 0 ]]; then
      continue
    fi

    ipAddr=$(echo "$line" | awk -F, '{print $1}')
    ipSpeed=$(echo "$line" | awk -F, '{print $6}')

    if [[ $ipSpeed = "0.00" ]]; then
      if [[ $current_line -eq 1 ]]; then
        log "没有符合条件的IP，检查能否正常测速"
        return 1
      else
        log "满足条件的IP数不足，仍然进行更新"
      fi
    fi

    ips+=("${ipAddr}")
    ip_counter=$((ip_counter + 1))

    if [[ ${ip_counter} -ge "$count" ]]; then
      break
    fi

  done <"$csv_file"
  echo "${ips[@]}"
}

makeData() {
  local type=$1
  local domain=$2
  local ip=$3

  local data='{
      "type": "'"$type"'",
      "name": "'"$domain"'",
      "content": "'"$ip"'",
      "ttl": 60,
      "proxied": false
  }'
  echo "$data"
}

updateDNSRecords() {
  local domain=$1
  local type=${2:-"A"}
  local ips
  read -r -a ips <<<"$3"

  local success_count=0
  local create_count=0
  local delete_count=0

  # Ensure zone_id and api_key are set
  if [[ -z "$zone_id" || -z "$api_key" ]]; then
    log "Error: 未设置zone_id或api_key"
    return 1
  fi

  log "为${domain}更新${ips[@]}"

  # Get existing DNS records
  local base_url="https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records"
  local params="name=${domain}&type=${type}"
  local auth_header="Authorization: Bearer $api_key"
  local json_header="Content-Type: application/json"
  local response=$(curl -sm10 --retry 3 -X GET "$base_url?$params" -H "$auth_header" -H "$json_header")

  if [[ $(echo "$response" | jq -r '.success') != "true" ]]; then
    log "获取DNS记录失败"
    return 1
  fi
  local records
  records=$(echo "$response" | jq -c '.result')

  # Update or delete existing DNS records
  local ip_index=0
  for record in $(echo "$records" | jq -c '.[]'); do
    local record_id=$(echo "$record" | jq -r '.id')
    local update_url="$base_url/$record_id"
    local ip="${ips[$ip_index]}"

    # If no corresponding IP, delete the record
    if [[ -z "$ip" ]]; then
      local response=$(curl -sm10 --retry 3 -X DELETE "$update_url" -H "$auth_header" -H "$json_header")
      if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
        delete_count=$((delete_count + 1))
      fi
    else
      # Update existing record
      local data=$(makeData "$type" "$domain" "$ip")
      local response=$(curl -sm10 --retry 3 -X PUT "$update_url" -H "$auth_header" -H "$json_header" -d "$data")
      if [[ $(echo "$response" | jq -r '.success') == "true" ]] \
      || [[ $(echo "$response" | jq -r '.errors | select(length == 1 and .[0].code == 81057)') ]]; then
        success_count=$((success_count + 1))
      fi
    fi
    ip_index=$((ip_index + 1))
  done

  # Create new DNS records for remaining IPs
  while [[ $ip_index -lt ${#ips[@]} ]]; do
    local ip="${ips[$ip_index]}"
    local data=$(makeData "$type" "$domain" "$ip")
    local response=$(curl -sm10 --retry 3 -X POST "$base_url" -H "$auth_header" -H "$json_header" -d "$data")
    if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
      success_count=$((success_count + 1))
      create_count=$((create_count + 1))
    fi
  done

  echo "$success_count $create_count $delete_count"
}

cf_common_command="$CloudflareST $CFST_URL_R -t $CFST_T -n $CFST_N -dn $CFST_DN -tl $CFST_TL -dt $CFST_DT -tp $CFST_TP -sl $CFST_SL -p $CFST_P -tlr $CFST_TLR $CFST_STM"

if [ "$IP_ADDR" = "ipv4" ] || [ "$IP_ADDR" = "dualstack" ]; then
  (
    grep -v '^$' ./cf_ddns/ip.txt
    grep -v '^$' ./cf_ddns/pr_ip.txt
  ) >./merged_ip.txt
  if [ "$SKIP_ST" = "0" ]; then
    $cf_common_command -f ./merged_ip.txt -o ./volume/result_4.csv
  fi
  ips="$(loadIPs "./volume/result_4.csv" "$IP_COUNT")"
  for hostname in "${HOSTNAMES[@]}"; do
    read -r -a update_result <<<"$(updateDNSRecords "$hostname" "A" "$ips")"
    if [[ ${#update_result[@]} -ne 3 ]]; then
      log "$hostname 更新失败，检查网络或token"
      continue
    fi
    log "域名: $hostname A记录: ${update_result[0]}成功，${update_result[1]}新增，${update_result[2]}删除"
  done
fi

if [ "$IP_ADDR" = "ipv6" ] || [ "$IP_ADDR" = "dualstack" ]; then
  if [ "$SKIP_ST" = "0" ]; then
    $cf_common_command -f ./cf_ddns/ipv6.txt -o ./volume/result_6.csv
  fi
  ips="$(loadIPs "./volume/result_6.csv" "$IP_COUNT")"
  for hostname in "${HOSTNAMES[@]}"; do
    read -r -a update_result <<<"$(updateDNSRecords "$hostname" "AAAA" "$ips")"
    if [[ ${#update_result[@]} -ne 3 ]]; then
      log "$hostname 更新失败，检查网络或token"
      continue
    fi
    log "域名: $hostname AAAA记录: ${update_result[0]}成功，${update_result[1]}新增，${update_result[2]}删除"
  done
fi
log "测速及DNS更新完毕"
