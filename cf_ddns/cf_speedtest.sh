#!/bin/bash
# 构造命令
if [ "$IP_FAMILY" = "ipv4" ] || [ "$IP_FAMILY" = "dualstack" ]; then

    # 检查是否配置反代IP
    if [ "$IP_PR_IP" = "1" ]; then
        if curl -sm10 --retry 3 -X GET "$CFIP_URL" -o "$VOLUME_PATH"/pr_ip.txt; then
            echo "反代IP成功更新"
        else
            echo "反代IP更新失败，若存在更早版本的文件将使用旧文件"
        fi
    else
        rm -f "$VOLUME_PATH"/pr_ip.txt
    fi

    (
        grep -v '^$' "$VOLUME_PATH"/ip.txt
        grep -v '^$' "$VOLUME_PATH"/pr_ip.txt
    ) >"$VOLUME_PATH"/merged_ip.txt

    cfst_v4_command="$CloudflareST -f $VOLUME_PATH/merged_ip.txt -o $VOLUME_PATH/result_4.csv"
    [[ "$CFST_URL" == http* ]] && cfst_v4_command+=" -url $CFST_URL"
    [[ -n "$CFST_TP" ]] && cfst_v4_command+=" -tp $CFST_TP"
    [[ -n "$CFST_HTTPING" ]] && [[ "$CFST_HTTPING" -eq 1 ]] && {
        cfst_v4_command+=" -httping"
        [[ -n "$CFST_HTTPING_CODE" ]] && cfst_v4_command+=" -httping-code $CFST_HTTPING_CODE"
        [[ -n "$CFST_CFCOLO" ]] && cfst_v4_command+=" -cfcolo $CFST_CFCOLO"
    }
    [[ -n "$CFST_T" ]] && cfst_v4_command+=" -t $CFST_T"
    [[ -n "$CFST_N" ]] && cfst_v4_command+=" -n $CFST_N"
    [[ -n "$CFST_DN" ]] && cfst_v4_command+=" -dn $CFST_DN"
    [[ -n "$CFST_TL" ]] && cfst_v4_command+=" -tl $CFST_TL"
    [[ -n "$CFST_TLL" ]] && cfst_v4_command+=" -tll $CFST_TLL"
    [[ -n "$CFST_DT" ]] && cfst_v4_command+=" -dt $CFST_DT"
    [[ -n "$CFST_TP" ]] && cfst_v4_command+=" -tp $CFST_TP"
    [[ -n "$CFST_SL" ]] && cfst_v4_command+=" -sl $CFST_SL"
    [[ -n "$CFST_P" ]] && cfst_v4_command+=" -p $CFST_P"
    [[ -n "$CFST_TLR" ]] && cfst_v4_command+=" -tlr $CFST_TLR"
    [[ -n "$CFST_DD" ]] && [[ "$CFST_DD" -eq 1 ]] && cfst_v4_command+=" -dd"

    log "IPV4测速开始..."
    start_time=$(date +%s)
    if [[ -n "$CFST_E_TIMEOUT" ]]; then
        eval timeout "$CFST_E_TIMEOUT" "$cfst_v4_command"
    else
        eval "$cfst_v4_command"
    fi
    end_time=$(date +%s)

    if [ $? -eq 124 ]; then
        log "IPV4测速超时，用时 $(parseSeconds $((end_time - start_time)))"
        rm -f "$VOLUME_PATH"/result_4.csv
    else
        log "IPV4测速完成，用时 $(parseSeconds $((end_time - start_time)))"
    fi

    rm -f "$VOLUME_PATH"/merged_ip.txt
fi

if [ "$IP_FAMILY" = "ipv6" ] || [ "$IP_FAMILY" = "dualstack" ]; then
    cfst_v6_command="$CloudflareST -f $VOLUME_PATH/ipv6.txt -o $VOLUME_PATH/result_6.csv"
    [[ "$CFST_URL_V6" == http* ]] && cfst_v6_command+=" -url $CFST_URL_V6"
    [[ -n "$CFST_TP_V6" ]] && cfst_v6_command+=" -tp $CFST_TP_V6"
    [[ -n "$CFST_HTTPING_V6" ]] && [[ "$CFST_HTTPING_V6" -eq 1 ]] && {
        cfst_v6_command+=" -httping"
        [[ -n "$CFST_HTTPING_CODE_V6" ]] && cfst_v6_command+=" -httping-code $CFST_HTTPING_CODE_V6"
        [[ -n "$CFST_CFCOLO_V6" ]] && cfst_v6_command+=" -cfcolo $CFST_CFCOLO_V6"
    }
    [[ -n "$CFST_T_V6" ]] && cfst_v6_command+=" -t $CFST_T_V6"
    [[ -n "$CFST_N_V6" ]] && cfst_v6_command+=" -n $CFST_N_V6"
    [[ -n "$CFST_DN_V6" ]] && cfst_v6_command+=" -dn $CFST_DN_V6"
    [[ -n "$CFST_TL_V6" ]] && cfst_v6_command+=" -tl $CFST_TL_V6"
    [[ -n "$CFST_TLL_V6" ]] && cfst_v6_command+=" -tll $CFST_TLL_V6"
    [[ -n "$CFST_DT_V6" ]] && cfst_v6_command+=" -dt $CFST_DT_V6"
    [[ -n "$CFST_TP_V6" ]] && cfst_v6_command+=" -tp $CFST_TP_V6"
    [[ -n "$CFST_SL_V6" ]] && cfst_v6_command+=" -sl $CFST_SL_V6"
    [[ -n "$CFST_P_V6" ]] && cfst_v6_command+=" -p $CFST_P_V6"
    [[ -n "$CFST_TLR_V6" ]] && cfst_v6_command+=" -tlr $CFST_TLR_V6"
    [[ -n "$CFST_DD_V6" ]] && [[ "$CFST_DD_V6" -eq 1 ]] && cfst_v6_command+=" -dd"
    log "IPV6测速开始..."
    start_time=$(date +%s)
    if [[ -n "$CFST_E_TIMEOUT_V6" ]]; then
        eval timeout "$CFST_E_TIMEOUT_V6" "$cfst_v6_command"
    else
        eval "$cfst_v6_command"
    fi
    end_time=$(date +%s)

    if [ $? -eq 124 ]; then
        log "IPV6测速超时，用时 $(parseSeconds $((end_time - start_time)))"
        rm -f "$VOLUME_PATH"/result_6.csv
    else
        log "IPV6测速完成，用时 $(parseSeconds $((end_time - start_time)))"
    fi
fi
