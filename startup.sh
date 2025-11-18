#!/bin/bash

# Script de inicialização para Dr. OCP Workstation Toolkit
# Verifica e clona os repositórios necessários e executa o ambiente local

echo "========================================"
echo "Dr. OCP Workstation Toolkit - Inicialização"
echo "========================================"
echo ""

# Obter o diretório do script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 1. Verificar se ./apps existe, criar se não existir
echo "Verificando diretório ./apps..."
if [ ! -d "./apps" ]; then
    echo "Criando diretório ./apps..."
    mkdir -p ./apps
    echo "Diretório ./apps criado."
else
    echo "Diretório ./apps já existe."
fi

# 2. Verificar e clonar dr-ocp-identity-manager
echo ""
echo "Verificando dr-ocp-identity-manager..."
if [ ! -d "./apps/dr-ocp-identity-manager" ]; then
    echo "Clonando dr-ocp-identity-manager..."
    git clone https://github.com/brhrmaster/dr-ocp-identity-manager.git ./apps/dr-ocp-identity-manager
    if [ $? -eq 0 ]; then
        echo "dr-ocp-identity-manager clonado com sucesso."
    else
        echo "ERRO: Falha ao clonar dr-ocp-identity-manager."
        exit 1
    fi
else
    echo "dr-ocp-identity-manager já existe."
fi

# 3. Verificar e clonar dr-ocp-admin-fe
echo ""
echo "Verificando dr-ocp-admin-fe..."
if [ ! -d "./apps/dr-ocp-admin-fe" ]; then
    echo "Clonando dr-ocp-admin-fe..."
    git clone https://github.com/brhrmaster/dr-ocp-admin-fe.git ./apps/dr-ocp-admin-fe
    if [ $? -eq 0 ]; then
        echo "dr-ocp-admin-fe clonado com sucesso."
    else
        echo "ERRO: Falha ao clonar dr-ocp-admin-fe."
        exit 1
    fi
else
    echo "dr-ocp-admin-fe já existe."
fi

# 4. Verificar e clonar dr-ocp-admin-be
echo ""
echo "Verificando dr-ocp-admin-be..."
if [ ! -d "./apps/dr-ocp-admin-be" ]; then
    echo "Clonando dr-ocp-admin-be..."
    git clone https://github.com/brhrmaster/dr-ocp-admin-be.git ./apps/dr-ocp-admin-be
    if [ $? -eq 0 ]; then
        echo "dr-ocp-admin-be clonado com sucesso."
    else
        echo "ERRO: Falha ao clonar dr-ocp-admin-be."
        exit 1
    fi
else
    echo "dr-ocp-admin-be já existe."
fi

# 5. Entrar na pasta ./dr-ocp-setup
echo ""
echo "Entrando na pasta ./setup..."
if [ ! -d "./dr-ocp-setup" ]; then
    echo "ERRO: Diretório ./dr-ocp-setup não encontrado."
    exit 1
fi

cd ./dr-ocp-setup

# 6. Executar run-locally.sh
echo ""
echo "Executando run-locally.sh..."
if [ ! -f "./run-locally.sh" ]; then
    echo "ERRO: Arquivo ./run-locally.sh não encontrado."
    exit 1
fi

chmod +x ./run-locally.sh
./run-locally.sh

cd ..