#! /bin/bash
#author links

function usage()
{
    echo "Usage:"
    echo "ping_ips.sh <ip_list_file>"

    echo "Example:"
    echo " iptables_create_port.sh ip_list.txt"
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
    usage
    exit 1
fi

if [ $# -eq 0 ] || [ $# -gt 1 ]; then
    usage
    exit 1
fi


ipfile=$1

echo --------------------ping start-------------------

for i in `cat $1`
do
    code=`ping -c 4 -W 3 $i | grep loss | awk '{print $6}'`

if [[ $code == 0% ]];
then
    echo -e "\033[32m ping \t $i \t Successed \t packet loss: $code \033[0m"
else
    echo -e "\033[31m ping \t $i \t Failed \t packet loss: $code \033[0m"
fi
done

echo --------------------ping stop--------------------
