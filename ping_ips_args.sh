#! /bin/bash
#author lkyn

IP_FILE=""
COUNT=""

function usage() {
echo "Usage:
    $0 -i <ip_file> [-c <ping_counts>]

Example:
    $0 -i ip_list.txt
    $0 -i ip_list.txt -c 2
"
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" || $# -eq 0 ]]; then
    usage
    exit 1
fi


while [[ "x$1" != "x" ]]
do
    case $1 in
        -i)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                IP_FILE=$2
                shift
            fi
            shift
            ;;
        -c)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                COUNT=$2
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

function do_ping() {
echo -------------------- ping start -------------------

for i in `cat $IP_FILE`
do
if [[ -z $COUNT ]]; #判断是否为空
then
    code=`ping -W 3 $i | grep loss | awk '{print $6}'`
else
    code=`ping -c $COUNT -W 3 $i | grep loss | awk '{print $6}'`
fi

if [[ $code == 0% ]];
then
    printf "\033[32m ping\t%-15s\tSuccessed\tpacket loss: %-6s\033[0m\n" "$i" "$code"
else
    printf "\033[31m ping\t%-15s\tFailed\t\tpacket loss: %-6s\033[0m\n" "$i" "$code"
fi

done

echo -------------------- ping stop ---------------------
}

do_ping
