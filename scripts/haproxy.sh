#! /bin/bash

ufw disable
systemctl disable --now ufw
systemctl stop ufw
systemctl disable apparmor
systemctl stop apparmor

install_tools() {
    apt update
    apt install -y tmux net-tools keepalived haproxy
}

check_apiserver() {
    cat > /etc/keepalived/check_apiserver.sh << EOF
#! /bin/bash

errorExit() {
    echo "*** $@" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/
if ip addr | grep 192.168.56.100; then
    curl --silent --max-time 2 --insecure https://192.168.56.100:6443/ -o /dev/null || errorExit "Error GET https://192.168.56.100:6443/"
fi
EOF

chmod +x /etc/keepalived/check_apiserver.sh
}

keepalived_config() {
    cat >> /etc/keepalived/keepalived.conf <<EOF
vrrp_script check_apiserver {
    script "/etc/keepalived/check_apiserver.sh"
    interval 3
    timeout 10
    fall 5
    rise 2
    weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth1
    virtual_router_id 1
    priotity 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass mysecret
    }
    virtual_ipaddress {
        192.168.56.100/24
    }
    track_script {
        check_apiserver
    }
}
EOF

systemctl enable keepalived
systemctl restart haproxy
}

haproxy_config() {
    cat >> /etc/haproxy/haproxy.cfg << EOF
frontend kubernetes-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance roundrobin
    server server-1 192.168.56.21:6443 check fall 3 rise 2
    server server-2 192.168.56.22:6443 check fall 3 rise 2
    server server-3 192.168.56.23:6443 check fall 3 rise 2
EOF

systemctl enable haproxy
systemctl restart haproxy
}


install_tools
check_apiserver
haproxy_config
keepalived_config