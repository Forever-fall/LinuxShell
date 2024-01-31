#!/bin/bash
# Author: lkyn

IP_FILE=""
PING_COUNT=""

# 打印用法
function usage() {
    echo "Usage: $0 -i <ip_file> [-c <ping_count>]"
}

# 参数检查
if [[ "$1" == "-h" || "$1" == "--help" || $# -eq 0 ]]; then
    usage
    exit 1
fi

# 解析参数
while [[ "$1" != "" ]]; do
    case $1 in
        -i)
            shift
            IP_FILE="$1"
            ;;
        -c)
            shift
            PING_COUNT="$1"
            ;;
        *)
            usage
            exit 1
            ;;
    esac
    shift
done

# 检查文件是否存在
if [ ! -f "$IP_FILE" ]; then
    echo "Error: IP file '$IP_FILE' not found!"
    exit 1
fi

# 执行 ping 测试
function do_ping() {
    echo "-------------------- ping start --------------------"
    while read -r ip; do
        if [[ -z "$PING_COUNT" ]]; then
            code=$(ping -W 3 "$ip" | grep loss | awk '{print $6}')
        else
            code=$(ping -c "$PING_COUNT" -W 3 "$ip" | grep loss | awk '{print $6}')
        fi

        if [[ "$code" == "0%" ]]; then
            printf "\033[32m ping\t%-15s\tSuccessed\tpacket loss: %-6s\033[0m\n" "$ip" "$code"
        else
            printf "\033[31m ping\t%-15s\tFailed\t\tpacket loss: %-6s\033[0m\n" "$ip" "$code"
        fi
    done < "$IP_FILE"
    echo "-------------------- ping stop ---------------------"
}

do_ping
