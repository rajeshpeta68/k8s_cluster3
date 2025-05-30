#!/bin/bash
########## k8s_worker_setup #################

set -euo pipefail
exec > >(tee /tmp/k8s-worker-install.log) 2>&1

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

log "Installing Docker"
sudo yum install -y yum-utils
sudo yum install -y docker
sudo systemctl enable --now docker

log "Adding user to Docker group"
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

log "Ensuring bridge-nf-call-iptables is enabled"
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables

log "Ensuring ip_forward is enabled"
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

log "Reloading sysctl settings"
sudo sysctl --system

log "Worker node setup complete!"
echo
echo "To join this node to the cluster, run the kubeadm join command provided by the control-plane node:"
echo
echo "  sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>"
echo
