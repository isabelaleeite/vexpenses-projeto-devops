provider "aws" {
  region = "us-east-1"
}

variable "projeto" {
  description = "Nome do projeto"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "IsabelaLeite"
}

terraform {
  backend "s3" {
    bucket  = "vexpenses-isabela-leite-state-bucket"  
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

# Geração de chave privada
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Par de chaves para a instância EC2
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}
