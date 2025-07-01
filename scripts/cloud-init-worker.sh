#!/bin/bash

set -e

echo "[INFO] Updating system packages..."
yum update -y

echo "[INFO] Installing Docker..."
yum install -y docker
systemctl enable --now docker

echo "[INFO] Setting SELinux to permissive..."
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo "[INFO] Adding Kubernetes repository..."
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.33/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

echo "[INFO] Installing Kubernetes components..."
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet
