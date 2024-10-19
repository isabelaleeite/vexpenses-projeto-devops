# Obtendo a versão mais recente do Debian 12
data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

# Instância EC2 Debian
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.id]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

 # Script de inicialização
  user_data = <<-EOF
              #!/bin/bash
              # Atualiza os repositórios e instala o Docker e o Git
              sudo apt-get update -y
              sudo apt-get install -y docker.io git

              # Habilita e inicia o serviço do Docker
              sudo systemctl start docker
              sudo systemctl enable docker

              # Clonar o repositório do GitHub
              git clone https://github.com/isabelaleeite/vexpenses-projeto-devops.git /app

              # Navega até o diretório do repositório clonado
              cd /app

              # Caso exista um Dockerfile, constrói e executa o contêiner Docker
              if [ -f Dockerfile ]; then
                sudo docker build -t vexpenses-app .
                sudo docker run -d -p 80:80 vexpenses-app
              else
                echo "Dockerfile não encontrado. Verifique o repositório."
              fi
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

# Outputs sensíveis
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}