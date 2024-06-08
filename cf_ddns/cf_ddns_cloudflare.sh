#!/bin/bash
#		版本：20231004
#         用于CloudflareST调用，更新hosts和更新cloudflare DNS。

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
  if [[ -z "$CF_ZONE_ID" || -z "$CF_API_KEY" ]]; then
    log "Error: 未设置zone_id或api_key"
    return 1
  fi

  # Get existing DNS records
  local base_url="https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records"
  local params="name=${domain}&type=${type}"
  local auth_header="Authorization: Bearer $CF_API_KEY"
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
      if [[ $(echo "$response" | jq -r '.success') == "true" ]] ||
        [[ $(echo "$response" | jq -r '.errors | select(length == 1 and .[0].code == 81057)') ]]; then
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

log "开始更新DDNS..."
if [ "$IP_FAMILY" = "ipv4" ] || [ "$IP_FAMILY" = "dualstack" ]; then
  ips="$(loadIPs "./volume/result_4.csv" "$CF_IP_COUNT")"
  if [[ -n $ips ]]; then
    log "ipv4优选结果：$ips"
    for hostname in "${CF_HOSTNAMES[@]}"; do
      log "开始更新A记录：${hostname}"
      read -r -a update_result <<<"$(updateDNSRecords "$hostname" "A" "$ips")"
      if [[ ${#update_result[@]} -ne 3 ]]; then
        log "$hostname 更新失败，检查网络或token"
        continue
      fi
      log "域名: $hostname A记录: ${update_result[0]}成功，${update_result[1]}新增，${update_result[2]}删除"
    done
  else
    log "没有获取到ipv4优选结果，跳过DDNS更新"
  fi
fi

if [ "$IP_FAMILY" = "ipv6" ] || [ "$IP_FAMILY" = "dualstack" ]; then
  ips="$(loadIPs "./volume/result_6.csv" "$CF_IP_COUNT")"
  if [[ -n $ips ]]; then
    log "ipv6优选结果：$ips"
    for hostname in "${CF_HOSTNAMES[@]}"; do
      log "开始更新AAAA记录：${hostname}"
      read -r -a update_result <<<"$(updateDNSRecords "$hostname" "AAAA" "$ips")"
      if [[ ${#update_result[@]} -ne 3 ]]; then
        log "$hostname 更新失败，检查网络或token"
        continue
      fi
      log "域名: $hostname AAAA记录: ${update_result[0]}成功，${update_result[1]}新增，${update_result[2]}删除"
    done
  else
    log "没有获取到ipv6优选结果，跳过DDNS更新"
  fi
fi
log "更新DDNS结束"