# Dr. Ocupacional - Ambiente Local

Este diretório contém os arquivos necessários para executar a aplicação localmente usando Docker Compose.

## Pré-requisitos

- Docker Desktop instalado e rodando
- PowerShell (Windows) ou Bash (Linux/Mac)

## Estrutura

- `docker-compose.yaml`: Configuração de todos os serviços (frontend, backend, identity, postgres, redis)
- `run-locally.ps1`: Script PowerShell para Windows
- `run-locally.sh`: Script Bash para Linux/Mac

## Variáveis de Ambiente

O docker-compose.yaml suporta as seguintes variáveis de ambiente (valores padrão entre parênteses):

### MSSQL Server
- `SA_PASSWORD`: Senha do usuário SA (Password123!)
- `MSSQL_SERVER_PORT`: Porta exposta (1433)

**Nota**: O banco de dados `dr_ocupacional` e as tabelas serão criados automaticamente na primeira execução através do script de inicialização.

### PostgreSQL Identity
- `POSTGRES_IDENTITY_DB`: Nome do banco de dados (dr_ocupacional_identity)
- `POSTGRES_IDENTITY_USER`: Usuário do banco (postgres)
- `POSTGRES_IDENTITY_PASSWORD`: Senha do banco (postgres123)
- `POSTGRES_IDENTITY_PORT`: Porta exposta (5433)

### Redis
- `REDIS_PORT`: Porta exposta (6379)

### Backend
- `BACKEND_PORT`: Porta exposta (8080)
- `ASPNETCORE_ENVIRONMENT`: Ambiente (Development)

### Identity
- `IDENTITY_PORT`: Porta exposta (8081)
- `ASPNETCORE_ENVIRONMENT`: Ambiente (Development)

### Frontend
- `FRONTEND_PORT`: Porta exposta (3000)
- `REACT_APP_API_URL`: URL da API backend (http://localhost:8080)
- `REACT_APP_IDENTITY_URL`: URL da API identity (http://localhost:8081)

## Como Executar

### Windows
```powershell
.\run-locally.ps1
```

### Linux/Mac
```bash
chmod +x run-locally.sh
./run-locally.sh
```

## Serviços Disponíveis

Após a execução, os seguintes serviços estarão disponíveis:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Identity API**: http://localhost:8081
- **MSSQL Server**: localhost:1433
- **PostgreSQL Identity**: localhost:5433
- **Redis**: localhost:6379

## Inicialização do Banco de Dados MSSQL

O banco de dados MSSQL será inicializado automaticamente quando o container for iniciado pela primeira vez. O script de inicialização (`requirements/init-mssql-database.sql`) cria:

- Database: `dr_ocupacional`
- Tabela: `tb_menu`
- Índices para otimização

### Inicialização Manual do Banco de Dados

Se precisar executar a inicialização manualmente após o container estar rodando:

**Quando rodando backend localmente (fora do Docker):**

```powershell
# Windows (PowerShell)
.\init-mssql-local.ps1
```

**Quando rodando tudo no Docker:**

```bash
# Linux/Mac
docker exec -i dr-ocupacional-mssql-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Password123!" -C -i /docker-entrypoint-initdb.d/init-mssql-database.sql

# Windows (PowerShell)
docker exec -i dr-ocupacional-mssql-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Password123!" -C -i /docker-entrypoint-initdb.d/init-mssql-database.sql
```

**Nota**: Se você está rodando o backend localmente (fora do Docker), certifique-se de que:
1. O container do MSSQL está rodando: `docker ps | findstr mssql`
2. O banco de dados foi inicializado executando `.\init-mssql-local.ps1`
3. A connection string no `appsettings.Development.json` usa `localhost` (não `mssql-server`)

## Comandos Úteis

### Parar todos os serviços
```bash
docker-compose down
```

### Parar e remover volumes
```bash
docker-compose down -v
```

### Ver logs
```bash
docker-compose logs -f [service-name]
```

### Rebuild de um serviço específico
```bash
docker-compose build [service-name]
docker-compose up -d [service-name]
```



