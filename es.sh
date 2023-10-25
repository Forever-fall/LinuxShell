#!/bin/bash

SCRIPT=`readlink -f $0`
CWD=`dirname $SCRIPT`

function usage {
    echo "usage:"
    echo "establish_ssh.sh <ip> <user> <password>"
    echo "If your password has special characters, such as &, put double quotation marks "" around the password"
    echo ""
    echo "example:"
    echo "./es.sh 10.10.10.10 root 1qaz2wsx"
    echo "./es.sh 10.10.10.10 root '1qaz2wsx&'"
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]];then
    usage
    exit 1
fi

if [ $# -eq 0 ] || [ $# -gt 4 ];then
    usage
    exit 1
fi

ip=$1
user=$2
password=$3

/bin/expect << EOF
spawn ssh-keygen -t rsa -n '' -f /$user/.ssh/id_rsa
expect {
    "*passphrase*" {send "\r";exp_continue}
    "*again*" {send "\r";}
}
expect eof
EOF

/bin/expect << EOF
set timeout 30
spawn ssh-copy-id -i /root/.ssh/id_rsa root@$ip
expect {
    "*password*" {
        send "$password\r";
    }
}
expect eof
EOF