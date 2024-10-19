# Desafio Terraform - Implementação na AWS com Docker

Este repositório contém o código Terraform para criar uma infraestrutura básica na AWS com uma instância EC2, Security Groups e automação do Nginx. Além disso, Docker foi adicionado como uma camada extra para facilitar a execução do código.

## Melhorias de Segurança

- **Grupo de Segurança**: O grupo de segurança foi configurado para permitir apenas as portas necessárias (HTTP - 80 e SSH - 22)

- **IAM Role**: Adicionada uma role IAM à instância EC2 para garantir controle de acesso seguro aos recursos da AWS.

## Automação do Nginx

- O Nginx é instalado e inicializado automaticamente após a criação da instância EC2 através do script `user_data`.
- Docker foi adicionado para executar o Nginx em um contêiner, garantindo consistência na execução do servidor web.

## Executando o Projeto

### Com Terraform Localmente

Se você já tem o Terraform instalado na sua máquina, siga os passos abaixo:

1. Clone o Repositório:
    ```bash
    git clone <URL_DO_REPOSITORIO>
    cd <NOME_DO_DIRETORIO>
    ```

2. Inicialize o Terraform:
    ```bash
    terraform init
    ```

3. Planeje a Infraestrutura:
    ```bash
    terraform plan
    ```

4. Aplique a Configuração:
    ```bash
    terraform apply
    ```

### Com Docker

Se você prefere usar Docker, siga os passos abaixo:

1. Crie a imagem Docker:
    ```bash
    docker build -t terraform-aws .
    ```

2. Execute o container Docker para inicializar o Terraform:
    ```bash
    docker run --rm -v $(pwd):/app terraform-aws init
    ```

3. Planeje e aplique a infraestrutura usando Docker:
    ```bash
    docker run --rm -v $(pwd):/app terraform-aws apply
    ```
# vexpenses-projeto-devops
