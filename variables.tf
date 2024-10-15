variable "instance_type" {
  type        = string
  description = "Instance type"
  default     = "t2.micro"
}

variable "access_key" {
  type        = string
  description = "aws access_key"
  default     = ""
}

variable "secret_key" {
  type        = string
  description = "aws secret_key"
  default     = ""
}

variable "region" {
  type    = string
  default = "us-east-1"
  
}
variable "ami" {
  type        = string
  description = "AMI ID"
  default     = "ami-0e86e20dae9224db8"
}

variable "config_path" {
  type        = string
  description = "Path to the kubernetes config file"
  default     = "~/.kube/config"
}
