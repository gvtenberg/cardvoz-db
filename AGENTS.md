# CardVoz Banco — Guia de referência para pessoas e agentes de IA

Leia este arquivo inteiro antes de alterar o banco. Ele vale para qualquer pessoa do grupo e para qualquer ferramenta (Claude Code, Cursor, Copilot, Codex etc.). O `CLAUDE.md` só aponta para cá. Como aplicar as migrations e conectar a API está no [`README.md`](README.md).

O CardVoz é um app de **fichas de estudo (flashcards) para pessoas cegas e com baixa visão**, que estudam com o leitor de tela do aparelho (TalkBack, NVDA). Este repositório é a **fonte da verdade do banco** (PostgreSQL no Supabase): a `cardvoz-api` só se conecta e não cria tabelas.

---

## 1. Regras inegociáveis

1. **Toda mudança de esquema é uma migration nova** em `supabase/migrations/` (`npx supabase migration new nome_em_portugues`). Nunca edite uma migration já aplicada no Supabase: o CLI não a roda de novo.
2. **Não apague dados.** Migration nova adiciona ou ajusta sem perder o que existe (coluna nova nula ou com padrão; nada de `DROP TABLE` em tabela com dados). Diga no cabeçalho: "Não apaga dados".
3. **O esquema bate com o modelo do Entity Framework da `cardvoz-api`.** Nomes em PascalCase e entre aspas (`"Decks"`, `"QuestionLanguage"`), os mesmos tipos e tamanhos. Para ver o SQL que o modelo espera: README, seção "Criar uma nova migration".
4. **Tabela nova nasce fechada:** `ENABLE ROW LEVEL SECURITY` sem política e permissões revogadas de `anon` e `authenticated`, como as outras. Só a API (usuário `postgres`) acessa os dados.
5. **IDs UUID v4**, nunca sequenciais.
6. **Valor que vai para a tela tem checagem** (`CHECK`). Ex.: o idioma das fichas vira atributo HTML, então só aceita código de idioma.
7. **Sem dados de exemplo e sem dados reais no repositório.** O `seed.sql` fica vazio: os baralhos são privados de cada pessoa.
8. **Commits sem atribuição a IA.** Sem `Co-Authored-By`, "Generated with…" ou menção a IA em commits e PRs.

---

## 2. O sistema (4 repositórios)

| Repositório | Papel |
|---|---|
| `cardvoz` | Site Next.js estático. Funciona sem conta (dados no aparelho); com conta, usa a API |
| `cardvoz-api` | API REST em C# (.NET 9); conecta neste banco pelo Session pooler do Supabase |
| **`cardvoz-db`** (este) | Esquema do banco, como migrations do Supabase CLI |
| `cardvoz-admin` | Painel da equipe: usuários e baralhos compartilhados |

- **Ordem de publicação** de mudança que mexe em tabela: migration aqui (`npx supabase db push`) → API → site. A API avisa no log se faltar migration.
- Tabelas: `"Users"`, `"RefreshTokens"`, `"Decks"`, `"Cards"`, `"StudySessions"`, `"StudyReviews"`. Baralho com `"UserId"` nulo é um baralho compartilhado (criado pelo painel); `"SourceDeckId"` diz de qual compartilhado uma cópia veio.

---

## 3. Formato de uma migration

- Nome: `AAAAMMDDhhmmss_assunto_em_portugues.sql` (ex.: `20261030000000_idioma_das_fichas.sql`).
- Cabeçalho em comentário, em português: o que muda, por quê, se apaga dados e qual tarefa da API acompanha.
- Atualize no `README.md` a estrutura de pastas e a tabela de tabelas.

---

## 4. Combinados da equipe

Estas regras vieram de conversas da equipe com assistentes de IA e valem para todo mundo, use ou não uma ferramenta de IA. Os `AGENTS.md` do `cardvoz` e da `cardvoz-api` têm a mesma seção, adaptada a cada repositório.

- **Português do Brasil** em respostas, comentários, commits, PRs e documentação. Quando a pessoa disser que entendeu, siga para o próximo passo sem repetir a explicação.
- **Documentação em toda mudança:** README e este arquivo atualizados junto com a migration.
- **Quem usa o CardVoz:** a cliente é cega e estuda com o TalkBack; o público inclui pessoas com baixa visão. O banco guarda o que permite isso (ex.: o idioma das fichas, para o leitor de tela trocar a voz).
- **Trabalho dividido:** cada repositório tem dono no grupo (`upstream` é o repositório do `fiuzaheitor`). Mudança de esquema só depois de combinar, porque a API precisa mudar junto; descreva a tarefa da API em `docs/tarefas/` da `cardvoz-api`.
- **Problemas** viram issue no GitHub do repositório certo. O commit que corrige cita a issue (`Closes #10`).
- **Pedido em andamento (out/2026):** a migration do idioma das fichas (`20261030000000_idioma_das_fichas.sql`) ainda precisa ser aplicada no Supabase depois do merge; a API ainda não lê as colunas (tarefa em `cardvoz-api/docs/tarefas/idioma-das-fichas.md`).
