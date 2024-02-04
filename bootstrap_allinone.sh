#!/bin/bash
#set -x

SCRIPT=$(readlink -f $0)
CWD=$(dirname ${SCRIPT})
PKG_DIR=$(dirname ${CWD})

function usage()
{
    echo "Usage:"
    echo "    bootstrap_allinone.sh [-p <pitrix_disk>] [-o <os_version>] [-m <mgmt_interface>] -a <mgmt_address> [-n <mgmt_netmask>] [-g <mgmt_gateway>] [-i <pxe_interface>] [-f]"
    echo "      <pitrix_disk> means the disk to mount the /pitrix directory."
    echo "      <os_version> means the qingcloud-firstbox os version, version of the current physical is default."
    echo "      <mgmt_interface> means the interface to create bridge to host qingcloud-firstbox"
    echo "      <mgmt_address> means the qingcloud-firstbox mgmt address, do not conflict."
    echo "      <mgmt_netmask> means the qingcloud-firstbox mgmt netmask, 255.255.255.0 is default."
    echo "      <mgmt_gateway> means the qingcloud-firstbox mgmt gateway, .254 is default."
    echo "      <pxe_interface> means the interface to config pxe network for bm provision."
    echo "      <-f> launch the firstbox no matter the firstbox have been launched"
    echo "Example:"
    echo "    bootstrap_allinone.sh -a 10.16.100.2"
    echo "    bootstrap_allinone.sh -a 10.16.100.2 -f"
    echo "    bootstrap_allinone.sh -p sdb1 -a 10.16.100.2"
    echo "    bootstrap_allinone.sh -p sda3 -o 16.04.3 -m bond0 -a 10.16.100.2 -i eth0"
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
    usage
    exit 1
fi

PITRIX_DISK=""
OS_VERSION=""
MGMT_INTERFACE=""
MGMT_ADDRESS=""
MGMT_NETMASK=""
MGMT_GATEWAY=""
PXE_INTERFACE=""
FORCE="False"

while [[ "x$1" != "x" ]]
do
    case $1 in
        -p)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                PITRIX_DISK=$2
                shift
            fi
            shift
            ;;
        -o)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                OS_VERSION=$2
                shift
            fi
            shift
            ;;
        -m)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                MGMT_INTERFACE=$2
                shift
            fi
            shift
            ;;
        -a)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                MGMT_ADDRESS=$2
                shift
            fi
            shift
            ;;
        -n)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                MGMT_NETMASK=$2
                shift
            fi
            shift
            ;;
        -g)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                MGMT_GATEWAY=$2
                shift
            fi
            shift
            ;;
        -i)
            if [[ "x$2" != "x" ]] && [[ $2 != "-"* ]]; then
                PXE_INTERFACE=$2
                shift
            fi
            shift
            ;;
        -f)
            FORCE="True"
            shift
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [[ "x${FORCE}" == "xFalse" ]] && [[ -f "${CWD}/bootstrap_allinone.Done" ]]; then
    echo "This node has been already bootstrapped, please check!"
    exit 0
fi

# enable_vt.sh
${CWD}/enable_vt.sh
if [[ $? -ne 0 ]]; then
    echo "Error: Exec enable_vt.sh failed, please check by [/root/enable_vt.log]!"
    exit 1
fi

# launch_fb.sh
arguments=""

# fixed PITRIX_DISK
PITRIX_DISK=$(lsblk | grep '/pitrix$' | awk '{print $1}' | awk -F '─' '{print $2}')
echo -n "${date} fixed PITRIX_DISK==${PITRIX_DISK}"

if [[ "x${PITRIX_DISK}" != "x" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -p ${PITRIX_DISK}"
    else
        arguments="-p ${PITRIX_DISK}"
    fi
fi

if [[ "x${OS_VERSION}" != "x" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -o ${OS_VERSION}"
    else
        arguments="-o ${OS_VERSION}"
    fi
fi

if [[ "x${MGMT_INTERFACE}" != "x" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -m ${MGMT_INTERFACE}"
    else
        arguments="-m ${MGMT_INTERFACE}"
    fi
fi

if [[ "x${MGMT_ADDRESS}" != "x" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -a ${MGMT_ADDRESS}"
    else
        arguments="-a ${MGMT_ADDRESS}"
    fi
fi

if [[ "x${MGMT_NETMASK}" != "x" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -n ${MGMT_NETMASK}"
    else
        arguments="-n ${MGMT_NETMASK}"
    fi
fi

if [[ "x${MGMT_GATEWAY}" != "x" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -g ${MGMT_GATEWAY}"
    else
        arguments="-g ${MGMT_GATEWAY}"
    fi
fi

if [[ "x${PXE_INTERFACE}" != "x" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -i ${PXE_INTERFACE}"
    else
        arguments="-i ${PXE_INTERFACE}"
    fi
fi

if [[ "x${FORCE}" != "xFalse" ]]; then
    if [[ -n ${arguments} ]]; then
        arguments="${arguments} -f"
    else
        arguments="-f"
    fi
fi

${CWD}/launch_fb.sh ${arguments}
if [[ $? -ne 0 ]]; then
    echo "Error: Exec launch_fb.sh failed, please check by [/root/launch_fb.log]!"
    exit 1
fi

# deploy.sh
ssh root@${MGMT_ADDRESS} "[[ -d /root/qingcloud-installer ]]" >/dev/null 2>&1
if [[ $? -ne 0 ]]; then
    date=$(date +'%Y-%m-%d %H:%M:%S')
    echo "${date} Warning: Automatic execution of the deploy.sh script failed, please execute it manually!"
else
    date=$(date +'%Y-%m-%d %H:%M:%S')
    echo -n "${date} Deploying the qingcloud-firstbox ... "
    # new a tmux session
    ssh root@${MGMT_ADDRESS} 'tmux new -s deploy -d' >/dev/null 2>&1
    ssh root@${MGMT_ADDRESS} 'tmux send-keys -t deploy /root/qingcloud-installer/bootstrap/deploy.sh Enter' >/dev/null 2>&1

    for ((i=0; i<60; i++))
    do
        ssh root@${MGMT_ADDRESS} 'grep "The installer is bootstrapped successfully." /root/deploy.log' >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            ssh root@${MGMT_ADDRESS} 'tmux kill-session -t deploy' >/dev/null 2>&1
            touch ${CWD}/bootstrap_allinone.Done
            echo -n "OK." && echo ""
            date=$(date +'%Y-%m-%d %H:%M:%S')
            echo "${date} The qingcloud-firstbox vm has been deployed successfully!"
            break
        fi

        ssh root@${MGMT_ADDRESS} 'egrep "Exec the function .* Error!" /root/deploy.log' >/dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            echo -n "Error!" && echo ""
            break
        fi

        sleep 30
    done
fi
