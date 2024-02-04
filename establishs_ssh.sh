#!/bin/bash

SCRIPT=`readlink -f $0`
CWD=`dirname ${SCRIPT}`

function usage()
{
    echo "Usage:"
    echo "    establish_ssh.sh <ip>/<ip_list> [<ssh_port> <user> <password>]"
    echo "      <ip> is the ip you want to establish ssh connection"
    echo "      <ip_list> is the ip list file including ips, one ip one line"
    echo "      <ssh_port> is the ssh port of the node, 22 is default"
    echo "      <user> is the user of the node, yop is default"
    echo "      <password> is the password of the node, zhu1241jie is default"
    echo "Example:"
    echo "    establish_ssh.sh 10.16.10.10"
    echo "    establish_ssh.sh /root/ip_list"
    echo "    establish_ssh.sh 10.16.10.10 22"
    echo "    establish_ssh.sh /root/ip_list 22 yop zhu1241jie"
}

if [[ "x$1" == "x-h" ]] || [[ "x$1" == "x--help" ]]; then
    usage
    exit 1
fi

if [[ $# -eq 0 ]] || [[ $# -gt 4 ]]; then
    usage
    exit 1
fi

IPS=$1
ssh_port=$2
user=$3
password=$4

num=`echo ${IPS} | tr '.' '\n' | wc -l`
if [[ ${num} -eq 4 ]]; then
    ips=${IPS}
elif [[ -f ${IPS} ]]; then
    ips=`cat ${IPS}`
else
    echo "The ip or ip list [${IPS}] is invalid!"
    exit 1
fi

if [[ "x${ssh_port}" == "x" ]]; then
    ssh_port='22'
fi

if [[ "x$user" == "x" ]]; then
    user='yop'
fi

if [[ "x$password" == "x" ]]; then
    password='zhu1241jie'
fi

# the node ssh port will be used
SSH_PORT=`cat /etc/ssh/sshd_config | grep 'Port' | grep -v '^#' | awk '{print $2}'`

function establish_ssh()
{
    local ip=$1

    # test if established
    ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no -p ${SSH_PORT} root@$ip "echo hello"
    if [[ $? -eq 0  ]]; then
        # copy ssh_config and sshd_config
        scp -P ${SSH_PORT} /etc/ssh/ssh_config ${ip}:/etc/ssh/
        scp -P ${SSH_PORT} /etc/ssh/sshd_config ${ip}:/etc/ssh/
        grep -wq "PasswordAuthentication yes" /etc/ssh/sshd_config
        if [[ $? -eq 0 ]]; then
            ssh -p ${SSH_PORT} ${ip} "sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config"
        fi
        ssh -p ${SSH_PORT} ${ip} "[ -f /etc/redhat-release ] && service sshd restart || service ssh restart"
        ssh -p ${SSH_PORT} root@${ip} "echo hello"
        return $?
    fi

    nc -w 3 -z ${ip} ${ssh_port}
    if [[ $? -ne 0 ]]; then
        log "Ssh server not running on port ${ssh_port}, or $ip is not reachable."
        return 1
    fi
    # refresh the known_hosts file
    ssh-keygen -f "/root/.ssh/known_hosts" -R $ip

    if [[ x"$user" == x"root" ]]; then
        home_dir="/root"
    else
        home_dir="/home/$user"
    fi
    /usr/bin/expect << EOF
set timeout 60
spawn scp -P ${ssh_port} -r /root/.ssh/ ${user}@${ip}:${home_dir}/
expect {
    "*(yes/no)*" {
        send "yes\r";
        exp_continue;
    }
    "*password*" {
        send "${password}\r";
        exp_continue;
    }
    eof
}
exit
EOF
    /usr/bin/expect << EOF
set timeout 60
spawn ssh -p ${ssh_port} -t ${user}:${password}@${ip} "sudo cp -r ${home_dir}/.ssh/ /root/"
expect {
    "*(yes/no)*" {
        send "yes\r";
        exp_continue;
    }
    "*password*" {
        send "${password}\r";
        exp_continue;
    }
    eof
}
exit
EOF
    scp -P ${ssh_port} /etc/ssh/ssh_config ${ip}:/etc/ssh/
    scp -P ${ssh_port} /etc/ssh/sshd_config ${ip}:/etc/ssh/
    # solve the problem of ssh may hang
    ssh -p ${ssh_port} ${ip} "sed -i '/pam_motd.so/d' /etc/pam.d/sshd"
    ssh -p ${ssh_port} ${ip} "sed -i '/pam_mail.so/d' /etc/pam.d/sshd"
    ssh -p ${ssh_port} ${ip} "export TERM=xterm; export DEBIAN_FRONTEND=noninteractive; if [[ \$(awk -F= '/^ID=/{print \$2}' /etc/os-release | sed 's@\"@@g') =~ (centos|kylin) ]]; then [[ -f /etc/pam.d/common-session ]] && sed -i '/pam_systemd.so/d' /etc/pam.d/common-session; else sed -i 's@^Default:.*@Default: no@g' /usr/share/pam-configs/systemd; pam-auth-update --package --remove systemd; fi"
    grep -wq "PasswordAuthentication yes" /etc/ssh/sshd_config
    if [[ $? -eq 0 ]]; then
        ssh -p ${ssh_port} ${ip} "sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config"
    fi
    ssh -p ${ssh_port} ${ip} "[ -f /etc/redhat-release ] && service sshd restart || service ssh restart"

    # refresh the known_hosts file for new ssh port
    hostname=$(ssh ${ip} "hostname")
    if [[ $? -eq 0 ]]; then
        ssh-keygen -f "/root/.ssh/known_hosts" -R ${hostname}
    fi
    ssh-keygen -f "/root/.ssh/known_hosts" -R ${ip}

    # re ssh after remove known_hosts
    /usr/bin/expect << EOF
set timeout 30
spawn ssh -p ${SSH_PORT} root@${ip} "echo hello"
expect {
    "*(yes/no)*" {
        send "yes\r";
        exp_continue;
    }
    eof
}
exit
EOF

    ssh -p ${SSH_PORT} root@${ip} "echo hello"
    return $?
}

mkdir -p /opt/log/node
log_file=/opt/log/node/establish_ssh.log

function log()
{
    msg=$*
    date=`date +'%Y-%m-%d %H:%M:%S'`
    echo "$date $msg" >> ${log_file}
}

function SafeEstablish()
{
    local ip=$1
    date=`date +'%Y-%m-%d %H:%M:%S'`
    echo -n "$date Establishing [$ip] ssh connection ... "
    log "Establishing [$ip] ssh connection ..."
    establish_ssh ${ip} >>${log_file} 2>&1
    if [[ $? -eq 0 ]]; then
        echo "OK."
        log "Establish [$ip] ssh connection OK."
    else
        echo "Error!"
        log "Establish [$ip] ssh connection Error!"
        exit 1
    fi
}

for ip in $ips; do
    # start establish
    SafeEstablish ${ip}
done
