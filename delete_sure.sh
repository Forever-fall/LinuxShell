#! /bin/bash

read -p "Please reconfirm that you want to delete the XXX.  (yes/no) " ans
while [[ "x"$ans != "xyes" && "x"$ans != "xno" && "x"$ans != "xy" && "x"$ans != "xn" ]]; do
    read -p "Please reconfirm that you want to delete the XXX.  (yes/no) " ans
done

if [[ "x"$ans == "xno" || "x"$ans == "xn" ]]; then
    exit
fi

function do_delete() {
echo "XXX is delete!"
}

function confirm() {
    msg=$*
    while [ 1 -eq 1 ]
    do
        read -r -p "${msg}" response
        case ${response} in
            [yY][eE][sS]|[yY])
                echo 0
                do_delete
                return
                ;;
            [nN][oO]|[nN])
                echo 1
                echo "exit!"
                return
                ;;
        esac
    done
}
confirm "are you sure =====!"