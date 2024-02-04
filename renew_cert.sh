#!/bin/bash
#author lkyn

function renew_cert() {
    /root/.acme.sh/acme.sh --cron --home /root/.acme.sh --force
    #echo "test to renew!!!!!!!"
}

function get_process_state() {
    status=""
    if [[ $process != " " ]];
    then
        status=`systemctl status $process | grep 'Active'| awk '{print $2}'`
        echo "$process is $status"
    else
    echo "Failed to get process_status!"
    fi
}

function start_process() {
    if [[ $process == 'nginx' ]];
    then
        systemctl start nginx
    elif [[ $process == 'httpd' ]]
    then
        systemctl start httpd
    else
        echo "It is not [nginx or httpd] that listens on port 80,so unable to start [nginx or httpd]"
        exit 0
    fi
}

process=""
count=`lsof -i :80 |wc -l`
for i in $(( $count - 1 ))
do
process=`lsof -i :80 |awk '{print $1}' |sed -n '2p'`

#if [[ -z $process ]];
if [[ $process == "nginx" || $process == "httpd" ]];
then
    if [[ $process == 'nginx' ]];
    then
        systemctl stop nginx
    elif [[ $process == 'httpd' ]]
    then
        systemctl stop httpd
    fi
else
    #既然不是nginx或httpd，那么就手动停止，这里直接退出(控制是未启动直接退出还是继续执行)
    #echo "It is not [nginx or httpd] that listens on port 80,exit!" && exit 0
    echo ""
fi
done

renew_cert

if [[ $process == "nginx" || $process == "httpd" ]]; then
    start_process
    get_process_state
else
    exit 0
fi




