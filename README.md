### README.md

# Desafio Terraform VExpenses

Este projeto usa Terraform para configurar e implantar um servidor Nginx em uma instância EC2 na AWS. Além de criar a infraestrutura necessária, ele também configura um bucket S3 para armazenar o estado do Terraform. A infraestrutura criada inclui uma VPC, sub-rede pública, gateway de internet, tabela de roteamento, grupo de segurança, instância EC2, e o Nginx é executado em um contêiner Docker dentro da EC2.

## Requisitos

- Conta na AWS
- Terraform instalado
- Chave SSH configurada para acessar a instância EC2

## Arquivos do Projeto

- `s3_bucket.tf`: Configuração do bucket S3 onde o estado do Terraform será armazenado.
- `main.tf`: Configuração principal do Terraform.
- `vpc.tf`: Configuração da VPC, sub-rede pública, gateway de internet e tabela de roteamento.
- `security_group.tf`: Define regras de segurança que controlam o tráfego de entrada e saída da instância EC2, permitindo apenas o tráfego autorizado, como o acesso via SSH e HTTP, enquanto bloqueia conexões não permitidas para proteger a instância.
- `ec2.tf`: Configura a instância EC2, utilizando o par de chaves e executando um script de inicialização que instala o Docker e executa o Nginx em um contêiner Docker.

## Estrutura do Projeto

```mermaid
graph TD;
    A[Terraform] --> S[S3 Bucket para estado remoto]
    A --> B[VPC]
    B --> C[Sub-rede Pública]
    B --> D[Gateway de Internet]
    C --> E[Tabela de Roteamento]
    C --> F[Grupo de Segurança]
    C --> G[Instância EC2]
    F --> G
    G --> I[Docker]
    I --> H[Nginx]
    E --> D
```

## Passos para Implantação

1. **Clone o Repositório:**

```bash
git clone https://github.com/isabelaleeite/vexpenses-projeto-devops.git
cd vexpenses-projeto-devops
```

2. **Crie o Bucket S3 para o Remote State:**

Entre na pasta onde o arquivo de configuração do bucket S3 está localizado:

```bash
cd 00-remote-state-bucket
```

3. **Inicialize o Terraform para o bucket S3:**

```bash
terraform init
```

4. **Aplique a configuração para criar o bucket S3:**

```bash
terraform apply
```
5. **Depois que o bucket S3 for criado, retorne à pasta principal:**

```bash
cd ..
```

6. **Inicialize a Configuração Principal:**

Navegue até a pasta principal do Terraform:

```bash
cd 01-terraform
```

7. **Inicialize o Terraform:**

```bash
terraform init
```

8. **Planeje a Infraestrutura:**

Verifique o plano de infraestrutura que será criado:

```bash
terraform plan
```

9. **Aplique a Configuração:**

Aplique a configuração para provisionar os recursos:

```bash
terraform apply
```

10. **Acesse o Servidor Nginx:**

Use o endereço IP público exibido no output do Terraform para acessar o servidor Nginx no navegador:

```bash
http://<instance_public_ip>
```

## Arquivos de Configuração

### `s3_bucket.tf`

```hcl
# Define o provedor AWS e especifica a região em que os recursos serão criados.
provider "aws" {
  region = "us-east-1"  # Região onde os recursos da AWS serão provisionados.
}

# Criação do bucket S3 que será utilizado para armazenar o estado do Terraform.
resource "aws_s3_bucket" "state_bucket" {
  bucket = "vexpenses-isabela-leite-state-bucket"  # Nome fixo do bucket S3.

  tags = {
    Name = "vexpenses-isabela-leite-state-bucket"  # Tag para identificar o bucket com o mesmo nome.
  }

  force_destroy = true  # Permite a exclusão do bucket mesmo se houver objetos armazenados nele.
}

# Configuração para habilitar o versionamento no bucket S3.
resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id  # Referencia o ID do bucket criado anteriormente.

  versioning_configuration {
    status = "Enabled"  # Habilita o versionamento para manter um histórico das versões dos arquivos armazenados.
  }
}
```

### `main.tf`

```hcl
# Define o provedor AWS e especifica a região em que os recursos serão criados.
provider "aws" {
  region = "us-east-1"  # Região onde os recursos da AWS serão provisionados.
}

# Variável para o nome do projeto. O valor padrão é "VExpenses".
variable "projeto" {
  description = "Nome do projeto"  # Descrição da variável.
  type        = string  # Tipo da variável (string).
  default     = "VExpenses"  # Valor padrão da variável.
}

# Variável para o nome do candidato. O valor padrão é "IsabelaLeite".
variable "candidato" {
  description = "Nome do candidato"  # Descrição da variável.
  type        = string  # Tipo da variável (string).
  default     = "IsabelaLeite"  # Valor padrão da variável.
}

# Configuração do backend do Terraform para armazenar o estado no S3.
terraform {
  backend "s3" {
    bucket  = "vexpenses-isabela-leite-state-bucket"  # Nome do bucket S3 onde o estado será armazenado.
    key     = "terraform.tfstate"  # Caminho/arquivo do estado no bucket.
    region  = "us-east-1"  # Região onde o bucket S3 está localizado.
    encrypt = true  # Ativa a criptografia para proteger os dados do estado.
  }
}
```

### `ec2.tf`

```hcl
# Obtendo a versão mais recente da AMI do Debian 12
data "aws_ami" "debian12" {
  most_recent = true  # Garante que a AMI mais recente será selecionada.

  # Filtro para buscar AMIs que tenham "debian-12-amd64-" no nome.
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  # Filtro para selecionar AMIs com tipo de virtualização "hvm".
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # ID do proprietário da AMI (neste caso, Debian).
  owners = ["679593333241"]
}

# Criação de uma instância EC2 usando a AMI Debian mais recente
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id  # ID da AMI obtida anteriormente.
  instance_type   = "t2.micro"  # Tipo da instância (pequena e de baixo custo).
  subnet_id       = aws_subnet.main_subnet.id  # Subnet onde a instância será criada.
  key_name        = aws_key_pair.ec2_key_pair.key_name  # Par de chaves para acesso SSH.
  security_groups = [aws_security_group.main_sg.id]  # Grupo de segurança associado.

  associate_public_ip_address = true  # Atribui um IP público à instância.

  # Configuração do volume root da instância.
  root_block_device {
    volume_size           = 20  # Tamanho do volume em GB.
    volume_type           = "gp2"  # Tipo de volume (SSD de uso geral).
    delete_on_termination = true  # Deleta o volume ao finalizar a instância.
  }

  # Script de inicialização (user_data) para instalar e configurar o Docker e o Nginx.
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              sudo docker run -d -p 80:80 --name nginx-server nginx
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"  # Tag para identificar a instância EC2.
  }
}

# Output sensível: chave privada para acessar a instância EC2
output "private_key" {
  description = "Chave privada para acessar a instância EC2"
  value       = tls_private_key.ec2_key.private_key_pem  # Exibe a chave privada.
  sensitive   = true  # Marca o output como sensível para ocultar em logs.
}

# Output: Endereço IP público da instância EC2
output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip  # Exibe o IP público da instância.
}

```
### `security_group.tf`

```hcl
# Grupo de segurança para a instância EC2
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de qualquer lugar e todo o trafego de saida"
  vpc_id      = aws_vpc.main_vpc.id # ID da VPC onde o grupo de segurança será criado.

  # Regras de entrada - SSH de qualquer lugar (porta 22)

  ingress {
    description      = "Permitir SSH de qualquer lugar"
    from_port        = 22 # Porta de origem.
    to_port          = 22 # Porta de destino.
    protocol         = "tcp"  # Protocolo usado.
    cidr_blocks      = ["0.0.0.0/0"]  # Permite acesso SSH de qualquer endereço IPv4.
    ipv6_cidr_blocks = ["::/0"] # Permite acesso SSH de qualquer endereço IPv6.
  }


  # Regras de entrada - Permitir acesso HTTP para Nginx (porta 80)

  ingress {
    from_port   = 80  # Porta de origem para HTTP.
    to_port     = 80  # Porta de destino para HTTP.
    protocol    = "tcp"  # Protocolo usado.
    cidr_blocks = ["0.0.0.0/0"]  # Permite acesso HTTP de qualquer endereço IPv4.
  }

  # Regras de saída - Permitir todo o tráfego de saída
  egress {
    description      = "Permitir todo o tráfego de saída"  # Descrição da regra.
    from_port        = 0  # Porta de origem (todas).
    to_port          = 0  # Porta de destino (todas).
    protocol         = "-1"  # Permite todos os protocolos.
    cidr_blocks      = ["0.0.0.0/0"]  # Permite tráfego de saída para qualquer endereço IPv4.
    ipv6_cidr_blocks = ["::/0"]  # Permite tráfego de saída para qualquer endereço IPv6.
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"  # Tag para identificar o grupo de segurança.
  }
}
```
### `vpc.tf`

 ```hcl
 # Criação da VPC pública
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"                    # Bloco CIDR que define a faixa de IPs da VPC
  enable_dns_support   = true                              # Habilita suporte a DNS na VPC
  enable_dns_hostnames = true                              # Habilita nomes de host baseados em DNS

  # Tags para identificação da VPC
  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"         # Nome da VPC, combinando o nome do projeto e do candidato
  }
}

# Criação da Subnet pública na VPC 
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id                  # ID da VPC onde a subnet será criada
  cidr_block        = "10.0.1.0/24"                        # Bloco CIDR que define a faixa de IPs da subnet
  availability_zone = "us-east-1a"                         # Zona de disponibilidade da subnet

  # Tags para identificação da subnet
  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"       # Nome da subnet, combinando o nome do projeto e do candidato
  }
}

# Criação do Internet Gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id                              # ID da VPC à qual o gateway será associado

  # Tags para identificação do Internet Gateway
  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"          # Nome do Internet Gateway, combinando o nome do projeto e do candidato
  }
}

# Criação da Tabela de Roteamento
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id                              # ID da VPC à qual a tabela de roteamento pertence

  # Definindo a rota padrão para permitir acesso à Internet
  route {
    cidr_block = "0.0.0.0/0"                                # Rota para todo o tráfego de saída
    gateway_id = aws_internet_gateway.main_igw.id         # Gateway associado à rota
  }

  # Tags para identificação da tabela de roteamento
  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"   # Nome da tabela de roteamento, combinando o nome do projeto e do candidato
  }
}

# Associação da tabela de rotas com a subnet
resource "aws_route_table_association" "main_associatio

```
## Aplicação de Melhorias

1. ### Divisão do Código em Múltiplos Arquivos

Organizei os recursos em diferentes arquivos (s3_bucket.tf, main.tf, ec2.tf, security_group.tf, vpc.tf). Essa modularização melhora a legibilidade e a manutenção do código, permitindo que as configurações de diferentes recursos sejam isoladas e facilitando tanto a compreensão quanto alterações futuras.

2. ### Configuração do Backend S3 e Versionamento do Estado

Implementei o uso de um bucket S3 para armazenar o estado do Terraform de forma segura, com versionamento e criptografia:

```hcl
resource "aws_s3_bucket" "state_bucket" {
  bucket = "vexpenses-isabela-leite-state-bucket"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

terraform {
  backend "s3" {
    bucket  = "vexpenses-isabela-leite-state-bucket"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

Essa modificação cria um bucket S3 dedicado para armazenar o estado do Terraform de forma centralizada e segura. O versionamento permite que um histórico das versões do estado seja mantido, facilitando a recuperação em caso de problemas, e a criptografia garante a proteção das informações sensíveis.

3. ### Atualização do Script de Inicialização na EC2 (ec2.tf)

Modifiquei o script de inicialização para instalar e configurar o Docker, além de iniciar um contêiner Nginx:

```bash
user_data = <<-EOF
  #!/bin/bash
  sudo apt-get update -y
  sudo apt-get install -y docker.io
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo docker run -d -p 80:80 --name nginx-server nginx
EOF
```

Essa modificação automatiza o provisionamento de um servidor Nginx em um contêiner Docker, configurando a instância EC2 para servir aplicações web de forma automática e padronizada.

4. ### Modificação no Grupo de Segurança (security_group.tf)

Adicionei uma regra para permitir tráfego HTTP (porta 80):

```hcl
ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}
```
Essa alteração permite que o servidor Nginx, rodando no contêiner, seja acessível publicamente pela porta 80. Ela é essencial para habilitar o acesso ao serviço web configurado. No entanto, reconheço que essa configuração poderia ser ajustada para restringir o acesso a uma faixa específica de IPs, caso seja necessário aumentar a segurança.

5. ### Atualização das Variáveis (main.tf)

Atualizei as variáveis projeto e candidato para refletirem o nome do projeto e o meu nome, deixando mais claro que os recursos pertencem a mim:

```hcl
variable "candidato" {
  default = "IsabelaLeite"
}
```

Isso facilita a identificação e o gerenciamento dos recursos, personalizando o ambiente de acordo com o meu contexto e o do projeto.


## Conclusão

Este projeto demonstra como usar Terraform para configurar uma infraestrutura na AWS, criar um bucket S3 para armazenar o estado do Terraform e implantar o Nginx em uma instância EC2 utilizando Docker. A infraestrutura automatizada inclui a criação de uma VPC, sub-rede, grupo de segurança, bucket S3 para o armazenamento remoto do estado, e uma instância EC2. O Nginx é iniciado dentro de um contêiner Docker, permitindo fácil implementação e escalabilidade.