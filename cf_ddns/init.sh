#!/bin/bash
#         用于CloudflareSpeedTestDDNS运行环境检测和必要软件初始化安装。

#github下在CloudflareSpeedTest使用ghproxy代理
PROXY=https://mirror.ghproxy.com/
VOLUME_PATH="./volume"
CloudflareST="$VOLUME_PATH/CloudflareST"
LATEST_URL=https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest

latest_version() {
	if [[ -n $CFST_E_VERSION ]]; then
		echo "$CFST_E_VERSION"
		return
	fi
	curl --silent $LATEST_URL | grep "tag_name" | cut -d '"' -f 4
}

if [ ! -f ${CloudflareST} ]; then
VERSION=$(latest_version)
get_arch=$(uname -m)
	if [[ $get_arch =~ "x86_64" ]]; then
		URL="https://github.com/XIU2/CloudflareSpeedTest/releases/download/$VERSION/CloudflareST_linux_amd64.tar.gz"
		curl -o /tmp/CFST.tar.gz ${PROXY}"$URL"
		tar -zxf /tmp/CFST.tar.gz -C /tmp/
		mv /tmp/CloudflareST /tmp/ip.txt /tmp/ipv6.txt "$VOLUME_PATH"
	elif [[ $get_arch =~ "aarch64" ]]; then
		URL="https://github.com/XIU2/CloudflareSpeedTest/releases/download/$VERSION/CloudflareST_linux_arm64.tar.gz"
		curl -o /tmp/CFST.tar.gz ${PROXY}"$URL"
		tar -zxf /tmp/CFST.tar.gz -C /tmp/
		mv /tmp/CloudflareST /tmp/ip.txt /tmp/ipv6.txt "$VOLUME_PATH"
	elif [[ $get_arch =~ "mips64" ]]; then
		URL="https://github.com/XIU2/CloudflareSpeedTest/releases/download/$VERSION/CloudflareST_linux_mips64.tar.gz"
		curl -o /tmp/CFST.tar.gz ${PROXY}"$URL"
		tar -zxf /tmp/CFST.tar.gz -C /tmp/
		mv /tmp/CloudflareST /tmp/ip.txt /tmp/ipv6.txt "$VOLUME_PATH"
	else
		log "找不到匹配的CloudflareST程序，请自行下载'https://github.com/XIU2/CloudflareSpeedTest'，并解压至'./cf_ddns/'文件夹中。"
		exit 1
	fi
	log "成功下载CloudflareST"
fi

if [[ ! -x ${CloudflareST} ]]; then
	chmod +x $CloudflareST
fi




