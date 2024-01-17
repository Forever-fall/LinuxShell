#! /bin/bash
#author links

function usage(){
    echo "Usage:"
    echo "ping_ips.sh <ip_list_file>"

    echo "Example:"
    echo "ping_ips.sh ip_list.txt"
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
    usage
    return 0
fi

if [ $# -eq 0 ] || [ $# -gt 1 ]; then
    usage
    return 0
fi


ipfile=$1

echo -------------------- ping start -------------------

for i in `cat $1`
do
    code=`ping -c 4 -W 3 $i | grep loss | awk '{print $6}'`

if [[ $code == 0% ]];
then
    printf "\033[32m ping\t%-15s\tSuccessed\tpacket loss: %-6s\033[0m\n" "$i" "$code"
else
    printf "\033[31m ping\t%-15s\tFailed\t\tpacket loss: %-6s\033[0m\n" "$i" "$code"
fi

done

echo -------------------- ping stop ---------------------