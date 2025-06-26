#!/bin/bash
set -euxo pipefail

# Disable swap
swapoff -a || true
sed -i '/ swap / s/^/#/' /etc/fstab

# Enable kernel modules
cat <<EOF > /etc/modules-load.d/k8s.conf
br_netfilter
EOF
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# Install containerd
dnf install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable --now containerd

# Add Kubernetes repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF

# Install Kubernetes components
dnf install -y kubelet kubeadm kubectl
systemctl enable --now kubelet

# Initialize control plane
if [ ! -f /etc/kubernetes/admin.conf ]; then
  kubeadm init --pod-network-cidr=192.168.0.0/16
fi

# Set up kubeconfig for ec2-user
mkdir -p /home/ec2-user/.kube
cp /etc/kubernetes/admin.conf /home/ec2-user/.kube/config
chown ec2-user:ec2-user /home/ec2-user/.kube/config

# Wait until API server is up

until kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes &> /dev/null; do
  echo "Waiting for API server..."
  sleep 5
done

# Apply Calico network
#kubectl --kubeconfig=/etc/kubernetes/admin.conf apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
#kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml