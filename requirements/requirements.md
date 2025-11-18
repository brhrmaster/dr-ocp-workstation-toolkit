# Prof of Concept - App Admin com módulo de gestão de Menus - Dr. Ocupacional

## Overview sobre a PoC (Checklist):

### Tela de Buscar Menu 
 - usuário realiza a busca por nome de menu
 - pode incluir um menu novo
 - pode editar ou excluir um menu pesquisado

### Tela de Cadastro de Menu

- usuário informa:
	- nome de menu
	- Ordem (numero)
	- ícone do menu (nome do icone selecionado de caixa de icones)
	
## UI/UX

### Linguagem visual (branding + saúde + inovação)

- Saúde ocupacional pede confiança, clareza, seriedade, mas "inovação" pede algo mais moderno, leve, sem cara de sistema de 2005.

## Paleta de cores

**Base neutra**
Cinza muito claro/off-white para fundo (#F5F7FA / #F2F4F7), texto em cinza escuro (#1F2933).

### Cor primária (marca/ação principal):

Tons de azul ou verde (flat style) são clássicos em saúde, mas opte por versões mais modernas:
- Azul: #2563EB / #1D4ED8
- Verde-azulado: #0D9488

Cores de apoio (status):
- Sucesso: verde suave (#22C55E)
- Alerta: âmbar (#F59E0B)
- Erro: vermelho (#EF4444)
- Informação: azul (#3B82F6)

Importante: cores fortes só para ações e status, não para fundos inteiros. Deixando o sistema respirar.

## Tipografia

Uma fonte sem serifa limpa, fácil em telas densas:
Inter, Roboto, Source Sans, Nunito são ótimas.

Tamanhos:
- Títulos de página: 22–24px (peso 600/700)
- Subtítulos/labels: 14–16px (peso 500)
- Texto/célula de tabela: 13–14px (peso 400)
- Evite tudo em caixa alta;
- Use maiúsculas apenas em pequenos labels ou botões bem específicos.

## Especificações Técnicas para o Front-End
- Next.JS (extraie o melhor do React de forma organizada e modular)
- Typescript
- MVVM
- Clean Code
- S.O.L.I.D. Principles
- MUI (Material UI) com customização forte para não ficar "cara padrão de Material"
- Testes unitários
- Arvore de pastas do app estrategicamente para melhor organização
- arquivo de configuração (appsettings) seguindo o que foi aplicado nos ENVIRONMENTS do docker-compose
- Após a authenticação pela API do identity app, utilizar "useState" para armazenar o access-token na memoria do navegador