#!/bin/bash

# Verificar se o GitHub CLI está instalado
if ! command -v gh &> /dev/null
then
    echo "GitHub CLI (gh) não está instalado. Instale antes de prosseguir."
    exit 1
fi

# Solicitar o nome do repositório
echo "Digite o nome do repositório no GitHub:"
read repo_name

# Solicitar a visibilidade do repositório (público ou privado)
echo "O repositório será público ou privado? (público/privado)"
read visibility

# Criar o repositório no GitHub
echo "Criando repositório no GitHub..."
gh repo create "$repo_name" --$visibility --confirm

# Inicializar Git localmente (se ainda não foi feito)
if [ ! -d ".git" ]; then
    echo "Inicializando repositório Git local..."
    git init
fi

# Adicionar todos os arquivos ao Git
echo "Adicionando arquivos ao repositório local..."
git add .

# Fazer o commit inicial
echo "Fazendo commit inicial..."
git commit -m "Commit inicial"

# Definir o repositório remoto no GitHub
echo "Adicionando repositório remoto..."
git remote add origin "https://github.com/$(gh auth status --show-token | grep Logged | awk '{print $3}')/$repo_name.git"

# Fazer o push para o GitHub
echo "Enviando os arquivos para o GitHub..."
git push -u origin master

echo "Repositório criado e enviado para o GitHub com sucesso!"
