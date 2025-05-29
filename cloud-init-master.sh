#!/bin/bash
########## k8s_setup #################

set -euo pipefail
exec > >(tee /tmp/k8s-install.log) 2>&1

log() { echo -e "\033[1;34m>>> $*\033[0m"; }

log "Disabling SELinux"
sudo setenforce 0 || true
sudo sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config || true

log "Disabling Swap"
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

log "Configuring sysctl for Kubernetes"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

log "Installing docker"
sudo yum install -y yum-utils
#sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#sudo yum install -y docker-ce docker-ce-cli containerd.io
sudo yum install -y docker
sudo systemctl enable --now docker

usermod -aG docker ec2-user
newgrp docker

log "Adding Kubernetes v1.29 repo"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

log "Installing Kubernetes v1.29 components"
sudo yum install -y kubelet-1.29.3 kubeadm-1.29.3 kubectl-1.29.3 cri-tools-1.29.0 --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

log "Loading br_netfilter kernel module"
sudo modprobe br_netfilter

log "Verifying br_netfilter is loaded"
lsmod | grep br_netfilter

log "Ensuring bridge-nf-call-iptables is enabled now"
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables

log "Ensuring ip_forward is enabled now"
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

log "Reloading sysctl settings"
sudo sysctl --system

log "Initializing Kubernetes control-plane node"
sudo kubeadm init 
#--pod-network-cidr=192.168.0.0/16 --cri-socket=unix:///var/run/dockershim.sock

log "Setting up kubectl config for the current user"
USER_HOME=$(getent passwd ec2-user | cut -d: -f6)
mkdir -p "$USER_HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$USER_HOME/.kube/config"
sudo chown ec2-user:ec2-user "$USER_HOME/.kube/config"

log "Applying Calico network plugin"
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

log "Kubernetes master node setup complete!"
echo
echo "To check the status of Calico pods, run:"
echo "  kubectl get pods -n kube-system"
echo
echo "To join worker nodes, run this command on each worker node:"
kubeadm token create --print-join-command

log "All done!"
