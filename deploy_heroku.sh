#!/bin/bash

# Script para organizar o projeto e realizar o deploy no Heroku

# Função para exibir mensagens
echo_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

echo_success() {
    echo -e "\e[32m[SUCCESS]\e[0m $1"
}

echo_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

# Verificar se o Heroku CLI está instalado
if ! command -v heroku &> /dev/null
then
    echo_error "Heroku CLI não está instalado. Por favor, instale-o antes de continuar."
    exit 1
fi

# Verificar se o Git está instalado
if ! command -v git &> /dev/null
then
    echo_error "Git não está instalado. Por favor, instale-o antes de continuar."
    exit 1
fi

# Passo 1: Organizar a Estrutura de Diretórios

echo_info "Criando a pasta 'public/'..."

# Criar a pasta public/ se não existir
if [ ! -d "public" ]; then
    mkdir public
    echo_success "Pasta 'public/' criada."
else
    echo_info "A pasta 'public/' já existe."
fi

echo_info "Movendo arquivos estáticos para 'public/'..."

# Mover arquivos HTML, CSS, JS, imagens e outras pastas para public/
# Evitar mover arquivos de backup ou desnecessários
mv index.html gravar.html painel.html requisitos.html public/ 2>/dev/null
mv css js img lib scss public/ 2>/dev/null
mv mobile-app-html-template.jpg public/ 2>/dev/null

echo_success "Arquivos estáticos movidos para 'public/'."

# Opcional: Remover arquivos de backup
if [ -f "index_backup.html" ]; then
    echo_info "Removendo 'index_backup.html'..."
    rm index_backup.html
    echo_success "'index_backup.html' removido."
fi

# Passo 2: Criar o Arquivo static.json

echo_info "Criando o arquivo 'static.json'..."

cat > static.json <<EOL
{
  "root": "public/",
  "clean_urls": false,
  "routes": {
    "/**": "index.html"
  }
}
EOL

echo_success "Arquivo 'static.json' criado."

# Passo 3: Inicializar o Repositório Git

if [ ! -d ".git" ]; then
    echo_info "Inicializando o repositório Git..."
    git init
    echo_success "Repositório Git inicializado."
else
    echo_info "Repositório Git já está inicializado."
fi

# Adicionar todos os arquivos ao Git
echo_info "Adicionando arquivos ao Git..."
git add .
echo_success "Arquivos adicionados ao Git."

# Verificar se há commits anteriores
if git rev-parse --verify HEAD >/dev/null 2>&1
then
    # Já há commits, adicionar um novo commit
    echo_info "Adicionando um novo commit..."
    git commit -m "Atualização - Organizando estrutura para deploy no Heroku" || {
        echo_error "Erro ao fazer commit. Verifique se há mudanças para commitar."
        exit 1
    }
else
    # Primeiro commit
    echo_info "Fazendo o commit inicial..."
    git commit -m "Commit inicial - Estrutura para deploy no Heroku" || {
        echo_error "Erro ao fazer o commit inicial."
        exit 1
    }
fi
echo_success "Commit realizado com sucesso."

# Passo 4: Fazer Login no Heroku (se necessário)

# Verificar se o usuário está logado no Heroku
if heroku auth:whoami &> /dev/null
then
    echo_info "Usuário já está logado no Heroku."
else
    echo_info "Fazendo login no Heroku..."
    heroku login
    if [ $? -ne 0 ]; then
        echo_error "Falha ao fazer login no Heroku."
        exit 1
    fi
    echo_success "Login no Heroku realizado com sucesso."
fi

# Passo 5: Criar o Aplicativo no Heroku com o Buildpack de NGINX

# Perguntar ao usuário se deseja especificar um nome para o aplicativo
read -p "Deseja especificar um nome para o aplicativo no Heroku? (s/n): " specify_name

if [[ "$specify_name" =~ ^[Ss]$ ]]
then
    read -p "Digite o nome desejado para o aplicativo: " app_name
    # Criar o aplicativo com o nome especificado e buildpack NGINX
    heroku create "$app_name" --buildpack https://github.com/heroku/heroku-buildpack-nginx.git
    if [ $? -ne 0 ]; then
        echo_error "Falha ao criar o aplicativo no Heroku. Verifique se o nome está disponível."
        exit 1
    fi
else
    # Criar o aplicativo com nome gerado automaticamente
    heroku create --buildpack https://github.com/heroku/heroku-buildpack-nginx.git
    if [ $? -ne 0 ]; then
        echo_error "Falha ao criar o aplicativo no Heroku."
        exit 1
    fi
fi

# Obter a URL do aplicativo criado
app_url=$(heroku apps:info -s | grep web_url | cut -d= -f2)
app_name=$(heroku apps:info -s | grep app | cut -d= -f2)

echo_success "Aplicativo criado no Heroku: $app_name"
echo_info "URL do aplicativo: $app_url"

# Passo 6: Criar o Arquivo de Configuração do NGINX

echo_info "Criando o arquivo 'config/nginx.conf.erb'..."

mkdir -p config

cat > config/nginx.conf.erb <<EOL
worker_processes 1;

events { worker_connections 1024; }

http {
    server {
        listen <%= ENV["PORT"] %>;

        root <%= ENV["ROOT"] || "public" %>;
        index index.html;

        location / {
            try_files \$uri \$uri/ =404;
        }
    }
}
EOL

echo_success "Arquivo 'config/nginx.conf.erb' criado."

# Passo 7: Fazer o Deploy para o Heroku

# Detectar a branch principal (main ou master)
current_branch=$(git branch --show-current)

if [ "$current_branch" == "main" ] || [ "$current_branch" == "master" ]; then
    echo_info "Fazendo o deploy da branch '$current_branch' para o Heroku..."
    git push heroku "$current_branch":master
else
    echo_info "Branch principal não é 'main' nem 'master'."
    echo_info "Detectando a branch atual: '$current_branch'."
    echo_info "Fazendo o deploy da branch '$current_branch' para o Heroku..."
    git push heroku "$current_branch":master
fi

if [ $? -ne 0 ]; then
    echo_error "Falha ao fazer o deploy para o Heroku."
    exit 1
fi

echo_success "Deploy realizado com sucesso no Heroku!"

# Passo 8: Acessar o Aplicativo

echo_info "Seu aplicativo está disponível em: $app_url"

# Fim do script
