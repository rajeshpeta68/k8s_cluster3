#!/bin/bash

LOGFILE="/tmp/troubleshoot.log"

{
  echo "===== ETCD status ====="
  sudo crictl ps | grep etcd || echo "etcd not found"

  echo
  echo "===== kube-apiserver status ====="
  sudo crictl ps | grep kube-apiserver || echo "kube-apiserver not found"

  echo
  echo "===== kubelet status ====="
  sudo systemctl status kubelet

  echo
  echo "===== containerd status ====="
  sudo systemctl status containerd

  echo
  echo "===== Port 6443 listener ====="
  sudo ss -tulpn | grep 6443 || echo "No listener on port 6443"

  echo
  echo "===== Recent kubelet logs ====="
  sudo journalctl -u kubelet -xe | tail -n 50

  echo
  echo "===== Timestamp: $(date) ====="
  echo
} >> "$LOGFILE" 2>&1
