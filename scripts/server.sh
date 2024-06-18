#! /bin/bash

swapoff -a; sed -i '/swap/d' /etc/fstab

ufw disable
systemctl disable --now ufw
systemctl stop ufw
systemctl disable apparmor
systemctl stop apparmor

containerd_config() {
    cat >> /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
}

k8s_networking() {
    cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
}

install_containerd() {
    apt update
    apt install -y containerd
    mkdir /etc/containerd
    containerd config default > /etc/containerd/config.toml
    sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
    systemctl restart containerd
    systemctl enable containred
}

k8s_repo() {
    apt install -y apt-transport-https ca-certificates curl gpg net-tools
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

install_kubeadm() {
    apt update
    apt install -y kubelet=1.28.1-1.1 kubeadm=1.28.1-1.1 kubectl=1.28.1-1.1
    apt-mark hold kubelet kubeadm kubectl
}

bootstrap_server_1() {
    kubeadm init --control-plane-endpoint="192.168.56.100:6443" --upload-certs --apiserver-advertise-address=192.168.56.21 --pod-network-cidr=192.168.0.0/16
    
    sleep 60s
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/tigera-operator.yaml
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/custom-resources.yaml

    # restart containerd for some reason
    systemctl restart containerd
}


containerd_config
k8s_networking

install_containerd
# k8s_repo
# install_kubeadm
