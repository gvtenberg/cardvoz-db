-- =============================================================================
-- CardVoz - tabela nova já nasce fechada para a Data API do Supabase
--
-- Todas as tabelas atuais têm RLS ligado, sem políticas, e REVOKE ALL para
-- anon e authenticated: com a URL do projeto e a chave anon, a Data API
-- (PostgREST/GraphQL) não lê nem grava nada. A API do CardVoz conecta direto no
-- Postgres com o usuário dono das tabelas e não passa por essas regras.
--
-- O Supabase, por padrão, dá acesso a anon e authenticated a toda tabela nova
-- criada no schema public. Se uma migration futura esquecer o REVOKE, a tabela
-- ficaria aberta. Aqui o padrão muda: o que o usuário postgres (o das
-- migrations) criar em public não ganha acesso para esses papéis. O RLS em
-- tabela nova continua obrigatório (AGENTS.md, regra 4).
--
-- Não muda tabelas existentes nem dados. Não há tarefa na API: ela não usa
-- esses papéis.
-- =============================================================================

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON TABLES FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON SEQUENCES FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON FUNCTIONS FROM anon, authenticated;
