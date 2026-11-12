-- =============================================================================
-- CardVoz - "Esqueci minha senha"
--
-- A pessoa pede a redefinição pelo e-mail; a API manda um link com um código
-- de uso único, válido por 1 hora. O banco guarda só o hash do código (como em
-- "RefreshTokens"): quem lê o banco não consegue usar o link.
--
-- Tabela nova, fechada como as outras (RLS sem política, sem acesso para anon
-- e authenticated). Não apaga dados.
-- Espelha o modelo do Entity Framework da cardvoz-api
-- (tarefa em cardvoz-api/docs/tarefas/conta-e-senha.md).
-- =============================================================================

CREATE TABLE "PasswordResetTokens" (
    "Id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "UserId" uuid NOT NULL,
    "TokenHash" character varying(64) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "UsedAt" timestamp with time zone,
    CONSTRAINT "PK_PasswordResetTokens" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_PasswordResetTokens_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_PasswordResetTokens_TokenHash" ON "PasswordResetTokens" ("TokenHash");

CREATE INDEX "IX_PasswordResetTokens_UserId" ON "PasswordResetTokens" ("UserId");

ALTER TABLE "PasswordResetTokens" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "PasswordResetTokens" FROM anon, authenticated;
