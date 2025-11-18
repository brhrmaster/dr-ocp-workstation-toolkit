# 1. Visão Geral

A **Identity API** será o serviço responsável por **autenticação, autorização e emissão de tokens** em uma arquitetura de microserviços, atendendo cenários:

* **frontend → backend** (apps web, mobile, SPAs)
* **backend → backend** (comunicação entre microserviços)

A API seguirá o padrão **OAuth 2.0** (com recomendação de uso de **OpenID Connect** para identidade de usuário), será implementada em **.NET Core 9** e utilizará **PostgreSQL** como banco de dados principal.

O projeto deve seguir:

* **Clean Code**
* **Clean Architecture**
* **DDD (Domain-Driven Design)**
* **SOLID Principles**
* **Testes unitários** com alta cobertura nas camadas de domínio e aplicação.
* Ser implementado na pasta /apps/identity

---

# 2. Objetivos

* Centralizar **autenticação e autorização** da plataforma.
* Garantir **segurança, rastreabilidade e padronização** no acesso aos microserviços.
* Fornecer **tokens OAuth2 (JWT)** para:
  * Usuários finais (usuários humanos).
  * Clients/microserviços (aplicações machine-to-machine).
* Permitir evolução e manutenção com **arquitetura modular, testável e extensível**.

---

# 3. Escopo

### 3.1. Incluso

* Gestão de **usuários** (cadastro, atualização, bloqueio).
* Gestão de **clients** (aplicações que consomem tokens).
* Implementação de **flows OAuth2**:
  * Authorization Code com **PKCE** (frontend → backend).
  * Client Credentials (backend → backend).
  * Refresh Token.
* Emissão e validação de **tokens JWT**.
* Gestão de **roles e permissões**.
* Registro de **auditoria básica** (login, logout, falhas de autenticação).
* API REST com documentação (ex: **OpenAPI/Swagger**).
* Testes unitários das regras de negócio e serviços de aplicação.

### 3.2. Fora de Escopo (por enquanto)

* Interface gráfica para administração (pode ser outro serviço/frontend).
* Integração com Identity Providers externos (Google, Azure AD, etc.) – pode ser previsto como extensão futura.
* MFA (Autenticação de múltiplos fatores) – opcional como futuro incremento.

---

# 4. Stakeholders

* **Usuários finais**: médicos, clínicas, RH (via aplicativos frontend).
* **Sistemas consumidores**: microserviços da plataforma (consultas, laudos, faturamento, etc.).
* **Equipe de desenvolvimento**: backend, frontend, DevOps.
* **Equipe de segurança**: responsável por políticas de autenticação/autorização.
* **Equipe de operações**: monitora saúde da aplicação e incidentes.

---

# 5. Requisitos Funcionais

## RF-01 – Cadastro e gestão de usuários

* RF-01.1: A API deve permitir **criação de usuários** com campos mínimos:
  * Nome completo
  * Email (único)
  * Senha (hash, nunca em texto puro)
  * Status (ativo, bloqueado, pendente, etc.)
* RF-01.2: Permitir **atualização de dados** (nome, email, atributos adicionais).
* RF-01.3: Permitir **bloqueio/desbloqueio** de usuários.
* RF-01.4: Permitir **desativação lógica** de usuários (soft delete).

## RF-02 – Cadastro e gestão de clients (aplicações)

* RF-02.1: A API deve gerenciar **clients OAuth2**:
  * `client_id`
  * `client_secret` (quando aplicável, armazenado com hash/cripto)
  * Tipo de client (confidential / public)
  * Allowed grant types (authorization_code, client_credentials, refresh_token)
  * Redirect URIs (para Authorization Code)
  * Allowed scopes
* RF-02.2: Permitir **criar, atualizar, revogar** clients.

## RF-03 – Fluxos de Autenticação OAuth2

### RF-03.1 Authorization Code com PKCE (usuário logando via frontend)

* Suportar fluxo **Authorization Code + PKCE** para SPAs / apps mobile/web.
* Endpoints:
  * `/oauth/authorize`
  * `/oauth/token`
* Deve:
  * Autenticar usuário (login com email + senha).
  * Validar `code_verifier`/`code_challenge`.
  * Emitir `authorization_code`.
  * Trocar `authorization_code` por **access_token** + **refresh_token**.

### RF-03.2 Client Credentials (backend → backend)

* Permitir autenticação de **microserviços** usando `client_id` + `client_secret`.
* Endpoint: `/oauth/token`.
* Emitir **access_token** com **claims de aplicação** (sem usuário humano).
* Respeitar scopes permitidos para o client.

### RF-03.3 Refresh Token

* Permitir renovação de access_token via **refresh_token** válido.
* Endpoint: `/oauth/token` (grant_type=refresh_token).
* Implementar:
  * Rotação de refresh tokens (invalidate old, issue new).
  * Expiração e revogação.

## RF-04 – Emissão de Tokens JWT

* RF-04.1: Access Tokens serão **JWT assinados** (ex: RS256/ES256).
* RF-04.2: Claims mínimas:
  * `sub` (usuário ou client)
  * `iss` (emissor)
  * `exp`, `iat`, `nbf`
  * `aud` (lista de microserviços / APIs)
  * `scope`
  * `roles` (quando usuário)
  * Identificador de tenant, se houver multi-tenant (opcional).
* RF-04.3: Possibilidade de expiração configurável por tipo de client/fluxo.

## RF-05 – Gestão de Roles e Permissões

* RF-05.1: Permitir definir **roles** (ex: `MEDICO`, `RH`, `ADMIN_SISTEMA`).
* RF-05.2: Permitir atribuir roles a usuários.
* RF-05.3: Permitir mapear roles → permissões (ex: `LAUDO:CRIAR`, `COLABORADOR:VER`).
* RF-05.4: Claims de roles e permissões devem ser propagadas nos tokens.

## RF-06 – Auditoria

* RF-06.1: Registrar eventos de:
  * Login bem-sucedido
  * Login falho
  * Refresh de token
  * Revogação de token
  * Alterações em usuários e clients
* RF-06.2: Armazenar mínimos dados necessários (usuário, horário, IP, client_id).

## RF-07 – Endpoints de Utilidade

* RF-07.1: `/oauth/introspect`: checar validade de um token (opcional).
* RF-07.2: `/oauth/userinfo` (se usar OIDC): retornar dados do usuário logado.
* RF-07.3: `/well-known/openid-configuration` (descoberta automática de metadados).

---

# 6. Requisitos Não Funcionais

## RNF-01 – Performance

* Deve suportar **baixa latência** nas principais operações (< 200ms p95 em cenário normal).
* Preparado para **escalar horizontalmente** (stateless – usar cache compartilhado quando necessário).

## RNF-02 – Disponibilidade

* Planejar para operar em ambiente **containerizado** (Kubernetes / Docker).
* Sem manutenção manual para rotação de chaves, secrets etc (integração com secret manager da infra se disponível).

## RNF-03 – Segurança

* Hash de senhas com algoritmo forte (ex: PBKDF2, bcrypt, argon2).
* Proteção contra:
  * Brute force (rate limiting em login).
  * SQL Injection (ORM / parâmetros).
  * XSS/CSRF (em endpoints de UI, se houver).
* TLS obrigatório em todas as comunicações.
* Segregar permissões de banco (usuário de DB com privilégios mínimos).

## RNF-04 – Observabilidade

* Log estruturado (correlation id, trace id).
* Métricas (ex: Prometheus) para:
  * Contagem de logins, falhas de login.
  * Latência dos endpoints.
  * Erros por tipo.
* Healthchecks:

  * `/health/live`
  * `/health/ready`

## RNF-05 – Manutenibilidade

* Código seguindo **Clean Code**: nomes claros, funções pequenas, baixa acoplamento e alta coesão.
* Arquitetura em camadas segundo **Clean Architecture**:
  * Domínio (Entities, Value Objects, Domain Services)
  * Aplicação (Use Cases / Application Services)
  * Infraestrutura (Repos, Providers, TokenServices concretos)
  * Interface (Controllers / DTOs / Mappers)
* Aplicação dos princípios **SOLID** em classes e serviços.

---

# 7. Modelagem e Arquitetura (alto nível)

## 7.1. Bounded Context: Identity

Dentro do DDD, o **Bounded Context Identity** engloba:

### Entidades principais (Domínio)

* `User`
  * Id
  * Name
  * Email
  * PasswordHash
  * Status
  * Roles (coleção)
* `Role`
  * Id
  * Name
  * Description
  * Permissions (coleção)
* `Permission`
  * Id
  * Name
  * Description
* `Client`
  * Id (`client_id`)
  * SecretHash
  * AllowedGrantTypes
  * RedirectUris
  * AllowedScopes
* `Token` (pode ser entidade ou valor + persistência de refresh tokens)
  * Id
  * UserId/ClientId
  * Type (access/refresh)
  * Expiration
  * Revoked (bool)

### Camadas (Clean Architecture)

* **Domain**:
  * Entities, Value Objects, Domain Services.
  * Sem dependência de .NET, frameworks ou infraestrutura.
* **Application**:
  * Use cases (ex: `AuthenticateUser`, `IssueToken`, `RegisterClient`).
  * Interfaces de repositório e gateways.
* **Infrastructure**:

  * Implementações de repositórios (PostgreSQL via ORM, ex: EF Core).
  * Serviços JWT (assinatura/validação).
  * Providers de criptografia/password hashing.
* **Presentation (API)**:
  * Controllers
  * DTOs (requests/responses)
  * Mapeamento entre DTOs e modelos de aplicação.

---

# 8. Integração com outros serviços

* Microserviços consumidores deverão:

  * Validar tokens JWT (via chave pública ou endpoint de JWKS).
  * Utilizar middleware de autenticação (ex: authentication/authorization middleware do .NET).
  * Basear autorização em claims de `scope`, `roles` e `permissions`.
* Para comunicação backend → backend:
  * Serviços poderão obter tokens via Client Credentials.
  * Podem ser definidos clients específicos para cada microserviço.

---

# 9. Testes

## RT-01 – Testes Unitários

* Cobrir principalmente:
  * Regras de autenticação (domain services).
  * Emissão e validação de tokens (sem depender de infra real).
  * Regras de roles e permissões.
  * Use cases da camada de aplicação.
* Ferramentas:
  * xUnit, NUnit ou MSTest (a definir).
  * Moq/Similar para mocks de repositórios e serviços.

## RT-02 – Testes de Integração (recomendado)

* Testes de fluxo completo (ex: login → emissão de token → refresh).
* Banco de dados de teste (PostgreSQL em container).

## RT-03 – Testes de Contrato (recomendado para microserviços)

* Validar contratos da API de Identity usados por outros serviços.
* Utilizar OpenAPI + testes automatizados (ex: Postman/Newman, pact tests, etc.).

---

# 10. Requisitos de Deploy e Configuração

* Deploy em ambiente **containerizado** (Docker).
* Configurações via **variáveis de ambiente**:
  * Connection string do PostgreSQL.
  * Secrets JWT (ou caminho para chaves assimétricas).
  * Opções de log/telemetria.
* Suporte a múltiplos ambientes:
  * dev / staging / production.
* Migrações de banco (ex: EF Core Migrations ou Flyway/Liquibase).