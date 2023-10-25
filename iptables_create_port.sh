#!/bin/bash

SCRIPT=`readlink -f $0`
CWD=`dirname $SCRIPT`

function usage()
{
    echo "Usage:"
    echo "iptables_create_port.sh <port>"

    echo "Example:"
    echo " iptables_create_port.sh 8090"
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
    usage
    exit 1
fi

if [ $# -eq 0 ] || [ $# -gt 1 ]; then
    usage
    exit 1
fi

PORT=$1

#禁止外部访问8080端口
iptables -I INPUT -p tcp --dport $PORT -j DROP
#允许本机访问8080端口
iptables -I INPUT -s 127.0.0.1 -p tcp --dport $PORT -j ACCEPT

#输出当前iptables规则
iptables -L -n
