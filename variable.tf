variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "EC2 Key pair name"
  type        = string
  default     = "id_rsa.pub"
}

variable "public_key_path" {
  description = "Path to the public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"

}

variable "instance_type_app" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_monitor" {
  type    = string
  default = "t3.small"
}
