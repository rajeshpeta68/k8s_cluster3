#!/bin/bash

set -e

# 1. Disable swap (required for kubeadm)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# 2. Enable required kernel modules and sysctl settings
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 3. Install containerd (container runtime)
yum install -y containerd
mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
systemctl enable --now containerd

# 4. Add Kubernetes repository
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

# 5. Install Kubernetes components (kubeadm, kubelet, kubectl)
yum install -y kubelet kubeadm kubectl
systemctl enable --now kubelet

# 6. Join the Kubernetes cluster
# Replace the below command with the actual output from "kubeadm join" on the master node
# Example:
# sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
echo "🔗 Please run the kubeadm join command provided by the control plane to join this node."
