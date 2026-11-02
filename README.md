# CardVoz — Banco de Dados (Supabase)

Esquema e dados iniciais do banco PostgreSQL do CardVoz, versionados como migrations do [Supabase CLI](https://supabase.com/docs/guides/cli).

Este repositório é a **fonte da verdade do banco**: a [`cardvoz-api`](../cardvoz-api) só se conecta e não cria tabelas. Toda mudança de esquema entra aqui como uma nova migration.

O CardVoz é um app de fichas de estudo para pessoas cegas e com baixa visão, com quatro repositórios: o site (`cardvoz`), a API (`cardvoz-api`), este banco e o painel da equipe (`cardvoz-admin`). Regras do banco e combinados da equipe, para pessoas e para ferramentas de IA: [`AGENTS.md`](AGENTS.md).

## Estrutura

```
supabase/
├── config.toml                                  # Configuração do Supabase CLI
├── migrations/
│   ├── 20261012000000_schema_inicial.sql        # Primeira versão (IDs numéricos, sem usuários)
│   ├── 20261013000000_usuarios_e_ids_aleatorios.sql  # Usuários, login e IDs UUID (recria as tabelas)
│   ├── 20261021000000_login_google.sql          # Login com Google (não apaga dados)
│   ├── 20261029000000_admin_e_baralhos_compartilhados.sql  # Admin e baralhos compartilhados (não apaga dados)
│   └── 20261030000000_idioma_das_fichas.sql     # Idioma das perguntas e das respostas (não apaga dados)
└── seed.sql                                     # Vazio: os baralhos são privados de cada usuário
```

### Tabelas

| Tabela | Conteúdo |
|---|---|
| `"Users"` | Contas (nome, e-mail único em minúsculas, ID da conta Google, hash da senha — nulo em quem entra só pelo Google —, bloqueio por tentativas, se é admin do painel) |
| `"RefreshTokens"` | Sessões de login (só o hash SHA-256 do token, validade, revogação) |
| `"Decks"` | Baralhos de cada usuário (título, categoria, descrição, slug único por usuário). Sem dono (`"UserId"` nulo) = baralho compartilhado, criado pelo painel; `"SourceDeckId"` aponta de qual compartilhado uma cópia veio; `"QuestionLanguage"`/`"AnswerLanguage"` guardam o idioma das fichas (nulo = português) |
| `"Cards"` | Fichas de cada baralho (pergunta, resposta, ordem) |
| `"StudySessions"` | Sessões de estudo (acertos, erros, início e fim) |
| `"StudyReviews"` | Cada resposta dada numa sessão |

Todos os IDs são UUID v4 aleatórios. Os nomes seguem o padrão do Entity Framework da API (PascalCase), então no SQL Editor do Supabase precisam de aspas: `SELECT * FROM "Decks";`

## Segurança

O Supabase publica automaticamente o esquema `public` numa API REST acessível pela chave pública `anon`. Para que os dados só sejam acessados pela `cardvoz-api`:

- **RLS ativo** em todas as tabelas, sem nenhuma política;
- **permissões revogadas** dos papéis `anon` e `authenticated`.

A `cardvoz-api` conecta com o usuário `postgres`, dono das tabelas, e por isso não é afetada pelo RLS.

## Como aplicar no Supabase

Pré-requisito: [Node.js](https://nodejs.org) (o CLI roda via `npx`, sem instalar nada).

```bash
# 1. Entrar na sua conta do Supabase (abre o navegador)
npx supabase login

# 2. Ligar este repositório ao seu projeto
#    (o "Reference ID" fica em Project Settings → General)
npx supabase link --project-ref <reference-id>

# 3. Cria as tabelas
npx supabase db push
```

Depois disso, a cada nova migration basta rodar `npx supabase db push`. Não há dados de exemplo: cada pessoa cria a própria conta no site.

### Primeiro admin do painel

Ninguém nasce admin. Depois de criar sua conta no site, abra o **SQL Editor** do Supabase e rode, com o seu e-mail:

```sql
UPDATE "Users" SET "IsAdmin" = true WHERE "Email" = 'seu-email@exemplo.com';
```

Os próximos admins são definidos pelo próprio painel (`cardvoz-admin`), na página **Usuários**.

## Conectar a API

No painel do Supabase, clique em **Connect → Session pooler** e copie a URI (porta 5432). Na `cardvoz-api`, coloque-a na variável `ConnectionStrings__DefaultConnection`, trocando `[YOUR-PASSWORD]` pela senha do banco.

- Use o **pooler**, não a conexão direta: a conexão direta do plano gratuito só funciona por IPv6, que hospedagens como o Render não suportam.
- A senha pode ter qualquer caractere: a API lê a URI sem depender de codificação. Troque `[YOUR-PASSWORD]` inteiro, inclusive os colchetes.

## Criar uma nova migration

```bash
npx supabase migration new nome_da_mudanca
```

Edite o arquivo criado em `supabase/migrations/` e aplique com `npx supabase db push`.

As tabelas precisam continuar batendo com o modelo do Entity Framework da `cardvoz-api`. Para ver o SQL que o modelo atual espera, rode na pasta da API:

```bash
dotnet tool install --global dotnet-ef
ConnectionStrings__DefaultConnection="Host=localhost" dotnet ef dbcontext script
```

## Para quem continua o projeto

- Leia o [`AGENTS.md`](AGENTS.md) antes de criar uma migration: regras (não apagar dados, tabela nova com RLS, nomes iguais aos do Entity Framework) e combinados da equipe. O `CLAUDE.md` só aponta para ele.
- **Ordem de publicação** de uma mudança que mexe em tabela: migration aqui (`npx supabase db push`) → API → site.
- **Pendente:** aplicar `20261030000000_idioma_das_fichas.sql` no Supabase depois do merge. A API ainda não lê as colunas novas (tarefa em `cardvoz-api/docs/tarefas/idioma-das-fichas.md`).
