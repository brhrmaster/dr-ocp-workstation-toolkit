# Melhorar Segurança JWT - Guia de Implementação

## Índice

1. [Situação Atual](#situação-atual)
2. [Problema Identificado](#problema-identificado)
3. [Solução: Persistir Chaves RSA](#solução-persistir-chaves-rsa)
4. [Implementação Técnica](#implementação-técnica)
5. [Impacto no Frontend](#impacto-no-frontend)
6. [Benefícios](#benefícios)
7. [Testes](#testes)
8. [Melhorias Futuras](#melhorias-futuras)
9. [Referências e Normativas](#referências-e-normativas)
10. [Artigos e Recursos](#artigos-e-recursos)

---

## Situação Atual

### Arquitetura Atual

1. **Identity Manager** (`dr-ocp-identity-manager`):
   - Gera tokens JWT assinados com **RS256** (RSA com SHA-256)
   - **Problema**: A chave RSA é gerada **temporariamente** a cada restart do servidor
   - Localização: `Program.cs` linha 69

2. **Backend API** (`dr-ocp-admin-be`):
   - Valida tokens via **Token Introspection** (RFC 7662)
   - Endpoint: `/oauth/introspect` do Identity Manager
   - Não valida a assinatura JWT diretamente

3. **Frontend** (`dr-ocp-admin-fe`):
   - Apenas envia o token no header `Authorization: Bearer {token}`
   - Não precisa validar tokens (responsabilidade do backend)

---

## Problema Identificado

### Problemas de Segurança

1. **Chave RSA Temporária**: 
   - A chave muda a cada restart do Identity Manager
   - Tokens antigos podem não ser validados corretamente após restart
   - Não há persistência da chave privada

2. **Risco de Comprometimento**:
   - Sem persistência, não há controle sobre a chave
   - Dificulta auditoria e rastreamento
   - Impossibilita rotação de chaves

3. **Falta de Padrão**:
   - Não segue as melhores práticas de OAuth 2.0
   - Não implementa JWKS (JSON Web Key Set) endpoint

### Evidência do Problema

No arquivo `Program.cs` do Identity Manager:

```csharp
// TODO: Carregar chave RSA de arquivo ou key vault em produção
// Por enquanto, gerar uma chave RSA temporária (não recomendado para produção)
var rsaKey = System.Security.Cryptography.RSA.Create(2048);
var signingKey = new Microsoft.IdentityModel.Tokens.RsaSecurityKey(rsaKey);
```

---

## Solução: Persistir Chaves RSA

### Visão Geral

Implementar um serviço que:
1. Gera um par de chaves RSA (privada/pública) na primeira execução
2. Persiste as chaves em arquivos seguros no servidor
3. Carrega as chaves existentes em execuções subsequentes
4. Protege as chaves com permissões restritas

### Arquitetura da Solução

```
Identity Manager
├── RsaKeyService (novo)
│   ├── Gera chaves RSA 2048 bits
│   ├── Salva em: keys/rsa-private-key.xml
│   └── Salva em: keys/rsa-public-key.xml
├── TokenService
│   └── Usa chave persistente para assinar tokens
└── Program.cs
    └── Carrega chave via RsaKeyService
```

---

## Implementação Técnica

### 1. Criar Serviço de Gerenciamento de Chaves RSA

**Arquivo**: `DrOcupacional.Identity.Infrastructure/Services/RsaKeyService.cs`

```csharp
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;

namespace DrOcupacional.Identity.Infrastructure.Services;

public class RsaKeyService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<RsaKeyService> _logger;
    private const string PrivateKeyPath = "keys/rsa-private-key.xml";
    private const string PublicKeyPath = "keys/rsa-public-key.xml";

    public RsaKeyService(IConfiguration configuration, ILogger<RsaKeyService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    public RsaSecurityKey GetSigningKey()
    {
        var rsa = LoadOrCreateRsaKey();
        return new RsaSecurityKey(rsa);
    }

    public RSA GetRsaKey()
    {
        return LoadOrCreateRsaKey();
    }

    private RSA LoadOrCreateRsaKey()
    {
        var keysDirectory = Path.GetDirectoryName(PrivateKeyPath) ?? "keys";
        
        // Garantir que o diretório existe
        if (!Directory.Exists(keysDirectory))
        {
            Directory.CreateDirectory(keysDirectory);
            _logger.LogInformation("Diretório de chaves criado: {Directory}", keysDirectory);
        }

        // Tentar carregar chave privada existente
        if (File.Exists(PrivateKeyPath))
        {
            try
            {
                var privateKeyXml = File.ReadAllText(PrivateKeyPath);
                var rsa = RSA.Create();
                rsa.FromXmlString(privateKeyXml);
                _logger.LogInformation("Chave RSA carregada de: {Path}", PrivateKeyPath);
                return rsa;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Erro ao carregar chave RSA existente. Gerando nova chave.");
            }
        }

        // Gerar nova chave RSA
        _logger.LogInformation("Gerando nova chave RSA de 2048 bits...");
        var newRsa = RSA.Create(2048);
        
        // Salvar chave privada
        var privateKeyXml = newRsa.ToXmlString(true);
        File.WriteAllText(PrivateKeyPath, privateKeyXml, Encoding.UTF8);
        _logger.LogInformation("Chave privada salva em: {Path}", PrivateKeyPath);

        // Salvar chave pública (opcional, para referência)
        var publicKeyXml = newRsa.ToXmlString(false);
        File.WriteAllText(PublicKeyPath, publicKeyXml, Encoding.UTF8);
        _logger.LogInformation("Chave pública salva em: {Path}", PublicKeyPath);

        // Definir permissões restritas (Linux/Mac)
        try
        {
            if (OperatingSystem.IsLinux() || OperatingSystem.IsMacOS())
            {
                // Apenas o proprietário pode ler/escrever
                File.SetUnixFileMode(PrivateKeyPath, UnixFileMode.UserRead | UnixFileMode.UserWrite);
                File.SetUnixFileMode(PublicKeyPath, UnixFileMode.UserRead | UnixFileMode.UserWrite);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Não foi possível definir permissões restritas nas chaves");
        }

        return newRsa;
    }
}
```

### 2. Atualizar Program.cs do Identity Manager

**Arquivo**: `DrOcupacional.Identity.Api/Program.cs`

**Substituir as linhas 66-73:**

```csharp
// Configurar JWT Authentication
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "DrOcupacional.Identity";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "ui-app";

// Registrar serviço de gerenciamento de chaves RSA
builder.Services.AddSingleton<DrOcupacional.Identity.Infrastructure.Services.RsaKeyService>();

// Obter chave RSA persistente
var rsaKeyService = builder.Services.BuildServiceProvider()
    .GetRequiredService<DrOcupacional.Identity.Infrastructure.Services.RsaKeyService>();
var signingKey = rsaKeyService.GetSigningKey();
var rsaKey = rsaKeyService.GetRsaKey();

builder.Services.AddSingleton(signingKey);
builder.Services.AddSingleton(rsaKey);
```

### 3. Atualizar DependencyInjection.cs da Infrastructure

**Arquivo**: `DrOcupacional.Identity.Infrastructure/DependencyInjection.cs`

Adicionar o registro do serviço:

```csharp
// Adicionar após os outros serviços
services.AddSingleton<DrOcupacional.Identity.Infrastructure.Services.RsaKeyService>();
```

### 4. Adicionar ao .gitignore

**Arquivo**: `.gitignore` (na raiz do projeto Identity Manager)

```
# Chaves RSA (nunca commitar!)
keys/
*.xml
!**/appsettings*.xml
```

### 5. Atualizar Dockerfile (Opcional)

Se estiver usando Docker, adicionar ao Dockerfile:

```dockerfile
# Criar diretório para chaves RSA
RUN mkdir -p /app/keys

# Definir permissões (se necessário)
RUN chmod 700 /app/keys
```

---

## Impacto no Frontend

### Nenhuma Mudança Necessária

O frontend **não precisa ser alterado** porque:

1. **Responsabilidade de Validação**: A validação de tokens é feita pelo backend via Token Introspection
2. **Envio de Token**: O frontend continua enviando o token no header `Authorization: Bearer {token}`
3. **Transparência**: A mudança é transparente para o frontend

### Comportamento Atual do Frontend

O frontend já implementa boas práticas:

- Tokens armazenados apenas em memória (não em `localStorage`)
- Renovação automática via refresh token
- Limpeza de tokens no logout

**Arquivo**: `apps/dr-ocp-admin-fe/src/services/auth.service.ts`

```typescript
// Tokens são armazenados apenas em memória (setState)
private accessToken: string | null = null;
private refreshToken: string | null = null;
```

---

## Benefícios

### Segurança

1. **Chave Persistente**: Não muda a cada restart
2. **Proteção de Chave Privada**: Armazenada com permissões restritas
3. **Auditoria**: Possibilidade de rastrear e auditar chaves
4. **Conformidade**: Segue melhores práticas de OAuth 2.0

### Compatibilidade

1. **Tokens Válidos**: Tokens continuam funcionando após restarts
2. **Sem Breaking Changes**: Não afeta o frontend ou backend existente
3. **Retrocompatibilidade**: Funciona com tokens já emitidos

### Escalabilidade

1. **Preparado para JWKS**: Base para implementar endpoint JWKS
2. **Rotação de Chaves**: Facilita implementação de rotação
3. **Key Vault**: Pode migrar para Azure Key Vault ou AWS Secrets Manager

---

## Testes

### Teste 1: Persistência de Chave

```bash
# 1. Iniciar Identity Manager
cd dr-ocp-setup
docker compose up -d dr-ocp-identity-manager

# 2. Verificar criação do diretório keys/
ls -la apps/dr-ocp-identity-manager/keys/

# 3. Fazer login e obter token
# 4. Reiniciar Identity Manager
docker compose restart dr-ocp-identity-manager

# 5. Verificar que o token anterior ainda funciona (até expirar)
```

### Teste 2: Validação de Assinatura

```bash
# 1. Obter token JWT
# 2. Decodificar no jwt.io
# 3. Verificar que a assinatura é válida
# 4. Tentar modificar o token e verificar que é rejeitado
```

### Teste 3: Permissões de Arquivo

```bash
# Verificar permissões da chave privada (Linux/Mac)
ls -la apps/dr-ocp-identity-manager/keys/rsa-private-key.xml

# Deve mostrar: -rw------- (apenas proprietário pode ler/escrever)
```

---

## Melhorias Futuras

### 1. JWKS Endpoint (Recomendado)

Implementar endpoint `/oauth/jwks` para expor a chave pública:

```csharp
[HttpGet("jwks")]
public IActionResult GetJwks()
{
    var rsa = _rsaKeyService.GetRsaKey();
    var publicKey = rsa.ExportRSAPublicKey();
    
    // Retornar no formato JWKS (RFC 7517)
    var jwks = new
    {
        keys = new[]
        {
            new
            {
                kty = "RSA",
                use = "sig",
                kid = "1",
                n = Base64UrlEncoder.Encode(publicKey),
                e = "AQAB"
            }
        }
    };
    
    return Ok(jwks);
}
```

**Referência**: [RFC 7517 - JSON Web Key (JWK)](https://tools.ietf.org/html/rfc7517)

### 2. Rotação de Chaves

Implementar suporte a múltiplas chaves para rotação:

- Manter chaves antigas por período de transição
- Suportar múltiplos `kid` (Key ID) no JWKS
- Revogar tokens antigos gradualmente

### 3. Key Vault Integration

Migrar para serviços gerenciados:

- **Azure Key Vault**: Para aplicações Azure
- **AWS Secrets Manager**: Para aplicações AWS
- **HashiCorp Vault**: Para ambientes on-premise

### 4. Validação Direta de Assinatura no Backend

Atualmente o backend usa Token Introspection. Opcionalmente, pode validar a assinatura diretamente:

```csharp
// No backend, validar assinatura JWT diretamente
// Requer acesso à chave pública via JWKS endpoint
```

---

## Referências e Normativas

### OAuth 2.0 e OpenID Connect

1. **RFC 7519 - JSON Web Token (JWT)**
   - https://tools.ietf.org/html/rfc7519
   - Especificação oficial do formato JWT

2. **RFC 7517 - JSON Web Key (JWK)**
   - https://tools.ietf.org/html/rfc7517
   - Formato para representar chaves criptográficas

3. **RFC 7518 - JSON Web Algorithms (JWA)**
   - https://tools.ietf.org/html/rfc7518
   - Algoritmos criptográficos para JWT (inclui RS256)

4. **RFC 7662 - OAuth 2.0 Token Introspection**
   - https://tools.ietf.org/html/rfc7662
   - Especificação do endpoint de introspect usado pelo backend

5. **RFC 6749 - OAuth 2.0 Authorization Framework**
   - https://tools.ietf.org/html/rfc6749
   - Framework completo do OAuth 2.0

6. **OpenID Connect Core 1.0**
   - https://openid.net/specs/openid-connect-core-1_0.html
   - Especificação do OpenID Connect

### OWASP (Open Web Application Security Project)

1. **OWASP Top 10**
   - https://owasp.org/www-project-top-ten/
   - Principais vulnerabilidades de segurança web

2. **OWASP JWT Cheat Sheet**
   - https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html
   - Guia de segurança para JWT

3. **OWASP Authentication Cheat Sheet**
   - https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
   - Melhores práticas de autenticação

### Microsoft Learn

1. **OAuth 2.0 e OpenID Connect**
   - https://learn.microsoft.com/pt-br/entra/identity-platform/v2-protocols
   - Documentação da Microsoft sobre OAuth 2.0

---

## Artigos e Recursos

### Artigos Técnicos (Medium e Blogs)

1. **Autenticação JWT: como proteger suas APIs de forma moderna**
   - https://www.rocketseat.com.br/blog/artigos/post/autenticacao-jwt-guia-proteger-api-nodejs
   - Guia completo sobre segurança JWT em APIs

2. **Segurança em APIs: Entendendo Autenticação e Autorização com OAuth e JWT**
   - https://devsjava.com.br/seguranca-em-apis-entendendo-autenticacao-e-autorizacao-com-oauth-e-jwt/
   - Explicação detalhada sobre OAuth e JWT

3. **JSON Web Token (JWT) - Guia Completo**
   - https://vantico.com.br/json-web-token-jwt/
   - Visão geral sobre JWT e suas aplicações

4. **Servidor JWKS - Implementação e Boas Práticas**
   - https://wfreitas.dev/posts/servidor-jwks/
   - Como implementar endpoint JWKS

5. **Segurança Avançada: OAuth2 e OpenID Connect**
   - https://apibrasil.blog/seguranca-avancada-oauth2-openid-connect/
   - Técnicas avançadas de segurança

### Vídeos e Tutoriais

1. **Explorando Vulnerabilidades em JWT: Testes Práticos de Segurança**
   - https://www.youtube.com/watch?v=a8AK1kVxLX8
   - Demonstração prática de vulnerabilidades

### Perigos e Vulnerabilidades Comuns

#### 1. **Algoritmo "none"**
- **Perigo**: Permite tokens sem assinatura
- **Solução**: Sempre validar o algoritmo e rejeitar "none"
- **Referência**: https://owasp.org/www-community/vulnerabilities/JSON_Web_Token_(JWT)_Cheat_Sheet_for_Java

#### 2. **Chaves Fracas ou Expostas**
- **Perigo**: Chaves comprometidas permitem falsificação de tokens
- **Solução**: Usar chaves fortes (RSA 2048+), proteger chave privada
- **Referência**: https://tools.ietf.org/html/rfc7518#section-3.3

#### 3. **Armazenamento Inseguro no Frontend**
- **Perigo**: Tokens em `localStorage` vulneráveis a XSS
- **Solução**: Usar cookies `HttpOnly` ou armazenamento em memória
- **Referência**: https://cheatsheetseries.owasp.org/cheatsheets/HTML5_Security_Cheat_Sheet.html

#### 4. **Falta de Validação de Claims**
- **Perigo**: Tokens expirados ou com claims inválidas aceitos
- **Solução**: Validar `exp`, `iss`, `aud`, `nbf`
- **Referência**: https://tools.ietf.org/html/rfc7519#section-4.1

#### 5. **Token Replay Attacks**
- **Perigo**: Tokens roubados podem ser reutilizados
- **Solução**: Implementar revogação de tokens, usar refresh tokens
- **Referência**: https://tools.ietf.org/html/rfc6749#section-10.4

### Recursos Adicionais

1. **JWT.io - Debugger**
   - https://jwt.io/
   - Ferramenta para decodificar e validar tokens JWT

2. **OAuth 2.0 Playground**
   - https://www.oauth.com/playground/
   - Ambiente interativo para testar OAuth 2.0

3. **Auth0 - JWT Handbook**
   - https://auth0.com/resources/ebooks/jwt-handbook
   - Guia completo sobre JWT (requer cadastro)

---

## Checklist de Implementação

- [ ] Criar `RsaKeyService.cs` na Infrastructure
- [ ] Atualizar `Program.cs` do Identity Manager
- [ ] Atualizar `DependencyInjection.cs` da Infrastructure
- [ ] Adicionar `keys/` ao `.gitignore`
- [ ] Atualizar `Dockerfile` (se aplicável)
- [ ] Testar persistência de chave
- [ ] Testar validação de assinatura
- [ ] Verificar permissões de arquivo
- [ ] Documentar processo de backup de chaves
- [ ] Implementar JWKS endpoint (opcional)
- [ ] Configurar rotação de chaves (opcional)

---

## Notas Importantes

### Segurança em Produção

1. **Nunca commitar chaves**: Sempre adicionar `keys/` ao `.gitignore`
2. **Backup seguro**: Fazer backup das chaves em local seguro
3. **Permissões restritas**: Garantir que apenas o processo do servidor acesse as chaves
4. **Monitoramento**: Monitorar tentativas de acesso não autorizado às chaves
5. **Rotação periódica**: Implementar processo de rotação de chaves

### Considerações de Compliance

- **LGPD/GDPR**: Tokens podem conter dados pessoais, garantir conformidade
- **PCI DSS**: Se processar pagamentos, seguir requisitos específicos
- **ISO 27001**: Implementar controles de segurança adequados

---

**Última atualização**: 2024-11-18  
**Autor**: Equipe Dr. Ocupacional  
**Versão**: 1.0

