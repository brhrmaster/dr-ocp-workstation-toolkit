# Script PowerShell para executar o ambiente local do Dr. Ocupacional
# Verifica se o Docker está instalado e executa o docker-compose

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dr. Ocupacional - Ambiente Local" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se o Docker está instalado
Write-Host "Verificando se o Docker está instalado..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version
    Write-Host "Docker encontrado: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "ERRO: Docker não está instalado ou não está no PATH." -ForegroundColor Red
    Write-Host "Por favor, instale o Docker Desktop: https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
    exit 1
}

# Verificar se o Docker está rodando
Write-Host "Verificando se o Docker está rodando..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "Docker está rodando." -ForegroundColor Green
} catch {
    Write-Host "ERRO: Docker não está rodando." -ForegroundColor Red
    Write-Host "Por favor, inicie o Docker Desktop e tente novamente." -ForegroundColor Yellow
    exit 1
}

# Verificar se o docker-compose está disponível
Write-Host "Verificando docker-compose..." -ForegroundColor Yellow
try {
    $composeVersion = docker-compose --version
    Write-Host "Docker Compose encontrado: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "AVISO: docker-compose não encontrado, tentando 'docker compose'..." -ForegroundColor Yellow
    try {
        $composeVersion = docker compose version
        Write-Host "Docker Compose (v2) encontrado." -ForegroundColor Green
        $useDockerComposeV2 = $true
    } catch {
        Write-Host "ERRO: Docker Compose não está disponível." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Iniciando serviços..." -ForegroundColor Cyan
Write-Host ""

# Navegar para o diretório local
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Executar docker-compose
if ($useDockerComposeV2) {
    docker compose up -d --build
} else {
    docker-compose up -d --build
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Serviços iniciados com sucesso!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Serviços disponíveis:" -ForegroundColor Cyan
    Write-Host "  - Frontend:    http://localhost:3000" -ForegroundColor White
    Write-Host "  - Backend API: http://localhost:8080" -ForegroundColor White
    Write-Host "  - Identity API: http://localhost:8081" -ForegroundColor White
    Write-Host ""
    Write-Host "Para ver os logs:" -ForegroundColor Yellow
    if ($useDockerComposeV2) {
        Write-Host "  docker compose logs -f" -ForegroundColor White
    } else {
        Write-Host "  docker-compose logs -f" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Para parar os serviços:" -ForegroundColor Yellow
    if ($useDockerComposeV2) {
        Write-Host "  docker compose down" -ForegroundColor White
    } else {
        Write-Host "  docker-compose down" -ForegroundColor White
    }
} else {
    Write-Host ""
    Write-Host "ERRO: Falha ao iniciar os serviços." -ForegroundColor Red
    exit 1
}