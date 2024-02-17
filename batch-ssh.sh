#!/bin/bash
#author lkyn

function usage {
    echo "Usage:
    -i,     Specify an ip to address to create SSH password-free
    -f,     Read the IP address list from the file to create SSH password-free in batches
    -u,     Specify the SSH username
    -p,     Specify the SSH password
    -P,     Specify the SSH port to establish password-free with the server on port 22 other than port 22

Example:
    $0 -i 10.10.10.10 -u root -p "1qaz2wsx"
    $0 -f /root/ip_list -u root -p "1qaz2wsx"
    $0 -i 10.10.10.10 -u root -p "1qaz2wsx" -P 28208
    $0 -f /root/ip_list -u root -p "1qaz2wsx" -P 28208
    
    该脚本尚有许多局限，需要安装expect，且只能创建本机到对端的单向ssh免密，无法完成双向互相免密 "
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" || $# -eq 0 ]]; then
    usage
    exit 0
fi

IP=""
IP_FILE=""
USER_NAME=""
PASSWORD=""
PORT=""

while [[ "x$1" != "x" ]]
do
    case $1 in
        -i)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                IP=$2
                shift
            fi
            shift
            ;;
        -f)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                IP_FILE=$2
                shift
            fi
            shift
            ;;
        -u)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                USER_NAME=$2
                shift
            fi
            shift
            ;;    
        -p)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                PASSWORD=$2
                shift
            fi
            shift
            ;;
        -P)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                PORT=$2
                shift
            fi
            shift 
            ;;                          
        *)
            usage
            exit 1
            ;;
    esac
done

function check_id_rsa_exist() {
    if [[ -f "/root/.ssh/id_rsa" ]]; then
        echo "id_rsa exist"
    else
        ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
    fi
}

function establish_ssh_ip_file() {
    for i in `cat $IP_FILE`
    do
    if [[ -z $PORT ]];
    then
    /usr/bin/expect << EOF
set timeout 60
spawn ssh-copy-id $USER_NAME@$i
expect {
    "*password*" {
        send "${PASSWORD}\r";
        exp_continue;
    }
    eof
}
exit
EOF
    else
    /usr/bin/expect << EOF
set timeout 60
spawn ssh-copy-id $USER_NAME@$i -p $PORT
expect {
    "*password*" {
        send "${PASSWORD}\r";
        exp_continue;
    }
    eof
}
exit
EOF
    fi
    done
}



function establish_ssh_single_ip() {
    if [[ -z $PORT ]];
    then
    /usr/bin/expect << EOF
set timeout 60
spawn ssh-copy-id $USER_NAME@$IP
expect {
    "*password*" {
        send "${PASSWORD}\r";
        exp_continue;
    }
    eof
}
exit
EOF
    else
    /usr/bin/expect << EOF
set timeout 60
spawn ssh-copy-id $USER_NAME@$IP -p $PORT
expect {
    "*password*" {
        send "${PASSWORD}\r";
        exp_continue;
    }
    eof
}
exit
EOF
    fi
}

if [[ -n $IP_FILE ]]; then
    check_id_rsa_exist
    establish_ssh_ip_file
elif [[ -n $IP ]]; then
    check_id_rsa_exist
    establish_ssh_single_ip
else
    usage
    exit 1
fi