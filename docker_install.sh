#!/bin/bash
#         用于CloudflareSpeedTestDDNS运行环境检测和必要软件初始化安装。

#github下在CloudflareSpeedTest使用ghproxy代理
PROXY=
CloudflareST="./cf_ddns/CloudflareST"
# 检测CloudflareST是否安装
LATEST_URL=https://api.github.com/repos/XIU2/CloudflareSpeedTest/releases/latest

latest_version() {
  curl --silent $LATEST_URL | grep "tag_name" | cut -d '"' -f 4
}

VERSION=$(latest_version)

if [ -e ./cf_ddns/tmp/ ]; then
	rm -rf ./cf_ddns/tmp/
fi
if [ ! -f ${CloudflareST} ]; then
	get_arch=$(uname -m)
	if [[ $get_arch =~ "x86_64" ]];then
	    echo "this is x86_64"
	    URL="https://github.com/XIU2/CloudflareSpeedTest/releases/download/$VERSION/CloudflareST_linux_amd64.tar.gz"
	    wget -P ./cf_ddns/tmp/ ${PROXY}$URL
	    tar -zxf ./cf_ddns/tmp/CloudflareST_linux_*.tar.gz -C ./cf_ddns/tmp/
	    mv ./cf_ddns/tmp/CloudflareST ./cf_ddns/tmp/ip.txt ./cf_ddns/tmp/ipv6.txt ./cf_ddns/
	    rm -rf ./cf_ddns/tmp/
	elif [[ $get_arch =~ "aarch64" ]];then
	    echo "this is arm64"
	    URL="https://github.com/XIU2/CloudflareSpeedTest/releases/download/$VERSION/CloudflareST_linux_arm64.tar.gz"
	    wget -P ./cf_ddns/tmp/ ${PROXY}$URL
	    tar -zxf ./cf_ddns/tmp/CloudflareST_linux_*.tar.gz -C ./cf_ddns/tmp/
	    mv ./cf_ddns/tmp/CloudflareST ./cf_ddns/tmp/ip.txt ./cf_ddns/tmp/ipv6.txt ./cf_ddns/
	    rm -rf ./cf_ddns/tmp/
	elif [[ $get_arch =~ "mips64" ]];then
	    echo "this is mips64"
	    URL="https://github.com/XIU2/CloudflareSpeedTest/releases/download/$VERSION/CloudflareST_linux_mips64.tar.gz"
	    wget -P ./cf_ddns/tmp/ ${PROXY}$URL
	    tar -zxf ./cf_ddns/tmp/CloudflareST_linux_*.tar.gz -C ./cf_ddns/tmp/
	    mv ./cf_ddns/tmp/CloudflareST ./cf_ddns/tmp/ip.txt ./cf_ddns/tmp/ipv6.txt ./cf_ddns/
	    rm -rf ./cf_ddns/tmp/
	else
	    echo "找不到匹配的CloudflareST程序，请自行下载'https://github.com/XIU2/CloudflareSpeedTest'，并解压至'./cf_ddns/'文件夹中。"
	    echo "找不到匹配的CloudflareST程序，请自行下载'https://github.com/XIU2/CloudflareSpeedTest'，并解压至'./cf_ddns/'文件夹中。" > $informlog
	    source $cf_push;
	    exit 1
	fi
fi
# 检测CloudflareST权限
if [[ ! -x ${CloudflareST} ]]; then
#   echo "${CloudflareST} 文件不可执行"
   chmod +x $CloudflareST
fi

echo "初始化完成！"
exit 0
