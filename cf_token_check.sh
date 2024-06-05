#!/bin/bash
config_file="./volume/config.conf"
source "$config_file"

res=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}" -H "Authorization: Bearer $api_key" -H "Content-Type:application/json");
resSuccess=$(echo "$res" | jq -r ".success");
if [[ $resSuccess != "true" ]]; then
  echo "登陆错误，检查cloudflare账号信息填写是否正确!"
else
  echo "Cloudflare账号验证成功";
fi