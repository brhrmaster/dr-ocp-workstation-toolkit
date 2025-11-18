# Dr. OCP Workstation Toolkit

## Objetivo do Projeto

O **Dr. OCP Workstation Toolkit** é uma ferramenta de desenvolvimento que facilita a configuração e execução de um ambiente local completo para o sistema Dr. Ocupacional. Este toolkit automatiza a clonagem dos repositórios necessários e a inicialização de todos os serviços relacionados através do Docker Compose.

O projeto integra os seguintes componentes:

- **dr-ocp-identity-manager**: Serviço de gerenciamento de identidade e autenticação
- **dr-ocp-admin-fe**: Frontend da aplicação administrativa
- **dr-ocp-admin-be**: Backend da API administrativa

Todos os serviços são executados em containers Docker, proporcionando um ambiente isolado e consistente para desenvolvimento.

## Pré-requisitos

Antes de executar o toolkit, certifique-se de ter instalado:

- **Git**: Para clonar os repositórios
- **Docker Desktop**: Para executar os containers (Windows/Mac) ou Docker Engine (Linux)
- **PowerShell**: Para Windows (já incluído no Windows 10/11)
- **Bash**: Para Linux/Mac (geralmente já incluído)

## Como Executar

### Windows

1. Abra o PowerShell no diretório raiz do projeto
2. Execute o script de inicialização:

```powershell
.\startup.ps1
```

### Linux/Mac

1. Abra o terminal no diretório raiz do projeto
2. Torne o script executável (apenas na primeira vez):

```bash
chmod +x startup.sh
```

3. Execute o script de inicialização:

```bash
./startup.sh
```

## O que o Script Faz

O script de inicialização (`startup.sh` ou `startup.ps1`) realiza as seguintes operações automaticamente:

1. **Verifica/Cria o diretório `./apps`**: Cria a pasta onde os repositórios serão clonados
2. **Clona os repositórios necessários**:
   - `dr-ocp-identity-manager` (se não existir)
   - `dr-ocp-admin-fe` (se não existir)
   - `dr-ocp-admin-be` (se não existir)
3. **Navega para a pasta `./dr-ocp-setup`**: Onde estão os arquivos de configuração do Docker Compose
4. **Executa o script de inicialização local**: 
   - Windows: `run-locally.ps1`
   - Linux/Mac: `run-locally.sh`

## Serviços Disponíveis

Após a execução bem-sucedida, os seguintes serviços estarão disponíveis:

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **Identity API**: http://localhost:8081
- **MSSQL Server**: localhost:1433
- **PostgreSQL Identity**: localhost:5433
- **Redis**: localhost:6379

## Estrutura do Projeto

```
dr-ocp-workstation-toolkit/
├── apps/                          # Repositórios clonados
│   ├── dr-ocp-identity-manager/  # Serviço de identidade
│   ├── dr-ocp-admin-fe/          # Frontend
│   └── dr-ocp-admin-be/          # Backend
├── setup/                         # Configurações Docker
│   ├── docker-compose.yaml       # Configuração dos serviços
│   ├── run-locally.ps1          # Script PowerShell
│   └── run-locally.sh            # Script Bash
├── startup.ps1                    # Script de inicialização (Windows)
├── startup.sh                    # Script de inicialização (Linux/Mac)
└── README.md                      # Este arquivo
```

## Comandos Úteis

Esteja certo que está na pasta `dr-ocp-setup` antes de executar os comandos:

```bash
cd ./dr-ocp-setup
```

### Ver logs dos serviços

```bash
# Windows (PowerShell)
docker compose logs -f

# Linux/Mac
docker compose logs -f
```

### Parar todos os serviços

```bash
docker compose down
```

### Parar e remover volumes (limpar dados)

```bash
docker compose down -v
```

### Reconstruir um serviço específico

```bash
docker compose build [nome-do-servico]
docker compose up -d [nome-do-servico]
```

## Solução de Problemas

### Erro ao clonar repositórios

- Verifique sua conexão com a internet
- Certifique-se de ter permissões para clonar os repositórios
- Verifique se o Git está instalado e no PATH

### Erro ao executar Docker

- Certifique-se de que o Docker Desktop está instalado e rodando
- Verifique se você tem permissões para executar comandos Docker
- No Linux, você pode precisar adicionar seu usuário ao grupo `docker`

### Portas já em uso

Se alguma porta já estiver em uso, você pode alterar as variáveis de ambiente no arquivo `dr-ocp-setup/docker-compose.yaml` ou criar um arquivo `.env` na pasta `dr-ocp-setup/`.

## Contribuindo

Para contribuir com este projeto:

1. Faça um fork do repositório
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

Este projeto é parte do ecossistema Dr. Ocupacional.

