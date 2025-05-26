#######################
output "master_ip" {
  value = aws_instance.k8s-master.public_ip
}

output "worker_ips" {
  value = [for inst in aws_instance.k8s-worker : inst.public_ip]
}