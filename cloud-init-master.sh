#!/bin/bash

# Update and install Docker
yum update -y
yum install -y docker
systemctl enable --now docker

usermod -aG docker ec2-user
newgrp docker

# Disable SELinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Disable swap (Kubernetes requirement)
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Add Kubernetes repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install Kubernetes components
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl enable --now kubelet

# Initialize Kubernetes cluster
kubeadm init --pod-network-cidr=192.168.0.0/16

# Configure kubectl for ec2-user
mkdir -p /home/ec2-user/.kube
cp -i /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config

# Install Calico CNI plugin
su - ec2-user -c "kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml"

# Output join command (save it for worker node)
kubeadm token create --print-join-command > /home/ec2-user/k8s-join.sh
chmod +x /home/ec2-user/k8s-join.sh
