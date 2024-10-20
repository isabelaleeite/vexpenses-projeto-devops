provider "aws" {
  region = "us-east-1"
}

# Criação do bucket S3 para o backend
resource "aws_s3_bucket" "state_bucket" {
  bucket = "vexpenses-isabela-leite-state-bucket"  # Nome fixo para o bucket

  tags = {
    Name = "vexpenses-isabela-leite-state-bucket"  # Nome fixo para as tags
  }

  force_destroy = true  # Para que o bucket seja excluído mesmo se possuir objetos
}

# Habilitar o versionamento do bucket
resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id

  versioning_configuration {
    status = "Enabled"  
  }
}
