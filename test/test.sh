#!/bin/bash

OUTPUT_FILE="/tmp/k8s-diagnostics.txt"
echo "Kubernetes Diagnostics - $(date)" > "$OUTPUT_FILE"
echo "=================================" >> "$OUTPUT_FILE"

echo -e "\n### Nodes Info" >> "$OUTPUT_FILE"
kubectl get nodes -o wide >> "$OUTPUT_FILE" 2>&1

echo -e "\n### kube-system Pods" >> "$OUTPUT_FILE"
kubectl get pods -n kube-system -o wide >> "$OUTPUT_FILE" 2>&1

echo -e "\n### Component Statuses" >> "$OUTPUT_FILE"
kubectl get componentstatuses >> "$OUTPUT_FILE" 2>&1

echo -e "\n### kube-dns Pods" >> "$OUTPUT_FILE"
kubectl get pods -n kube-system -l k8s-app=kube-dns >> "$OUTPUT_FILE" 2>&1

echo -e "\n### Running nginx pod" >> "$OUTPUT_FILE"
kubectl run test-nginx --image=nginx --restart=Never --port=80 >> "$OUTPUT_FILE" 2>&1

echo -e "\n### test-nginx Pod Details" >> "$OUTPUT_FILE"
kubectl get pod test-nginx -o wide >> "$OUTPUT_FILE" 2>&1

# echo -e "\n### test-nginx HTTP check" >> "$OUTPUT_FILE"
# kubectl exec -it test-nginx -- curl -I http://localhost >> "$OUTPUT_FILE" 2>&1

# echo -e "\n### Deleting test-nginx pod" >> "$OUTPUT_FILE"
# kubectl delete pod test-nginx >> "$OUTPUT_FILE" 2>&1

echo -e "\n### Running busybox pod" >> "$OUTPUT_FILE"
kubectl run busybox --image=busybox:1.28 --restart=Never -- sleep 3600 >> "$OUTPUT_FILE" 2>&1

echo -e "\n### DNS lookup from busybox" >> "$OUTPUT_FILE"
kubectl wait --for=condition=Ready pod/busybox --timeout=60s >> "$OUTPUT_FILE" 2>&1
kubectl exec -it busybox -- nslookup kubernetes >> "$OUTPUT_FILE" 2>&1

echo -e "\nDiagnostics saved to: $OUTPUT_FILE"
