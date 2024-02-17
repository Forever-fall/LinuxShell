#!/usr/bin/env bash
#system users UID ranges from 1 to 999
#Regular users UID ranges from 1000 onwards

getent passwd | awk -F : '$3 >= 1000 && $3 < 65344 || $3 == 0 {print $1} '
#getent passwd 0 {0..1002} |awk -F : '{print $1}'
echo ""
echo "User corresponding to UID"
echo ""
for i in {0..1000}
do
    if id $i &>/dev/null; then
        id $i
        #echo " "
    else
        continue
    fi
done
