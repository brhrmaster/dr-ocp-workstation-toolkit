# Script PowerShell de inicialização para Dr. OCP Workstation Toolkit
# Verifica e clona os repositórios necessários e executa o ambiente local

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Dr. OCP Workstation Toolkit - Inicialização" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Obter o diretório do script
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# 1. Verificar se ./apps existe, criar se não existir
Write-Host "Verificando diretório ./apps..." -ForegroundColor Yellow
if (-not (Test-Path "./apps")) {
    Write-Host "Criando diretório ./apps..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "./apps" -Force | Out-Null
    Write-Host "Diretório ./apps criado." -ForegroundColor Green
} else {
    Write-Host "Diretório ./apps já existe." -ForegroundColor Green
}

# 2. Verificar e clonar dr-ocp-identity-manager
Write-Host ""
Write-Host "Verificando dr-ocp-identity-manager..." -ForegroundColor Yellow
if (-not (Test-Path "./apps/dr-ocp-identity-manager")) {
    Write-Host "Clonando dr-ocp-identity-manager..." -ForegroundColor Yellow
    try {
        git clone https://github.com/brhrmaster/dr-ocp-identity-manager.git ./apps/dr-ocp-identity-manager
        Write-Host "dr-ocp-identity-manager clonado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "ERRO: Falha ao clonar dr-ocp-identity-manager." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "dr-ocp-identity-manager já existe." -ForegroundColor Green
}

# 3. Verificar e clonar dr-ocp-admin-fe
Write-Host ""
Write-Host "Verificando dr-ocp-admin-fe..." -ForegroundColor Yellow
if (-not (Test-Path "./apps/dr-ocp-admin-fe")) {
    Write-Host "Clonando dr-ocp-admin-fe..." -ForegroundColor Yellow
    try {
        git clone https://github.com/brhrmaster/dr-ocp-admin-fe.git ./apps/dr-ocp-admin-fe
        Write-Host "dr-ocp-admin-fe clonado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "ERRO: Falha ao clonar dr-ocp-admin-fe." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "dr-ocp-admin-fe já existe." -ForegroundColor Green
}

# 4. Verificar e clonar dr-ocp-admin-be
Write-Host ""
Write-Host "Verificando dr-ocp-admin-be..." -ForegroundColor Yellow
if (-not (Test-Path "./apps/dr-ocp-admin-be")) {
    Write-Host "Clonando dr-ocp-admin-be..." -ForegroundColor Yellow
    try {
        git clone https://github.com/brhrmaster/dr-ocp-admin-be.git ./apps/dr-ocp-admin-be
        Write-Host "dr-ocp-admin-be clonado com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "ERRO: Falha ao clonar dr-ocp-admin-be." -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "dr-ocp-admin-be já existe." -ForegroundColor Green
}

# 5. Entrar na pasta ./dr-ocp-setup
Write-Host ""
Write-Host "Entrando na pasta ./dr-ocp-setup..." -ForegroundColor Yellow
if (-not (Test-Path "./dr-ocp-setup")) {
    Write-Host "ERRO: Diretório ./dr-ocp-setup não encontrado." -ForegroundColor Red
    exit 1
}

Set-Location ./dr-ocp-setup

# 6. Executar run-locally.ps1
Write-Host ""
Write-Host "Executando run-locally.ps1..." -ForegroundColor Yellow
if (-not (Test-Path "./run-locally.ps1")) {
    Write-Host "ERRO: Arquivo ./run-locally.ps1 não encontrado." -ForegroundColor Red
    exit 1
}

& ./run-locally.ps1

Set-Location ..