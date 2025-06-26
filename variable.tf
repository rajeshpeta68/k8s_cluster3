
variable "region" {
  description = "The AWS region to deploy the Kubernetes cluster in"
  type        = string
  default     = "ap-south-1"

}



variable "instance_type" {
  description = "The type of EC2 instance to use for the Kubernetes cluster"
  type        = string
  default     = "t3.2xlarge"

}

variable "key_name" {
  description = "The name of the SSH key pair to use for accessing the EC2 instances"
  type        = string
  default     = "nasa"

}