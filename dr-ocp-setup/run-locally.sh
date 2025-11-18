#!/bin/bash

# Script Bash para executar o ambiente local do Dr. Ocupacional
# Verifica se o Docker está instalado e executa o docker-compose

echo "========================================"
echo "Dr. Ocupacional - Ambiente Local"
echo "========================================"
echo ""

# Verificar se o Docker está instalado
echo "Verificando se o Docker está instalado..."
if ! command -v docker &> /dev/null; then
    echo "ERRO: Docker não está instalado."
    echo "Por favor, instale o Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

DOCKER_VERSION=$(docker --version)
echo "Docker encontrado: $DOCKER_VERSION"

# Verificar se o Docker está rodando
echo "Verificando se o Docker está rodando..."
if ! docker info &> /dev/null; then
    echo "ERRO: Docker não está rodando."
    echo "Por favor, inicie o Docker e tente novamente."
    exit 1
fi
echo "Docker está rodando."

# Verificar se o docker-compose está disponível
echo "Verificando docker-compose..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_VERSION=$(docker-compose --version)
    echo "Docker Compose encontrado: $COMPOSE_VERSION"
    USE_COMPOSE_V2=false
elif docker compose version &> /dev/null; then
    echo "Docker Compose (v2) encontrado."
    USE_COMPOSE_V2=true
else
    echo "ERRO: Docker Compose não está disponível."
    exit 1
fi

echo ""
echo "Iniciando serviços..."
echo ""

# Navegar para o diretório local
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Executar docker-compose
if [ "$USE_COMPOSE_V2" = true ]; then
    docker compose up -d --build
else
    docker-compose up -d --build
fi

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Serviços iniciados com sucesso!"
    echo "========================================"
    echo ""
    echo "Serviços disponíveis:"
    echo "  - Frontend:    http://localhost:3000"
    echo "  - Backend API: http://localhost:8080"
    echo "  - Identity API: http://localhost:8081"
    echo ""
    echo "Para ver os logs:"
    if [ "$USE_COMPOSE_V2" = true ]; then
        echo "  docker compose logs -f"
    else
        echo "  docker compose logs -f"
    fi
    echo ""
    echo "Para parar os serviços:"
    if [ "$USE_COMPOSE_V2" = true ]; then
        echo "  docker compose down"
    else
        echo "  docker-compose down"
    fi
else
    echo ""
    echo "ERRO: Falha ao iniciar os serviços."
    exit 1
fi