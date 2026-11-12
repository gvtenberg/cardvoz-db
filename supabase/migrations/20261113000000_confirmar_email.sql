-- =============================================================================
-- CardVoz - confirmação de e-mail
--
-- O cadastro com senha não confirmava o e-mail, então a API não juntava a conta
-- com senha e a do Google do mesmo endereço (quem cadastrasse o e-mail de outra
-- pessoa entraria na conta dela). Agora a API manda um link de confirmação.
--
-- "Users":
-- - "EmailConfirmedAt": quando o e-mail foi confirmado. Nulo = não confirmado.
--   Confirmar não é obrigatório para usar o CardVoz; serve para juntar a conta
--   com o Google com segurança.
-- "EmailConfirmationTokens": códigos do link (só o hash, uso único, 24 horas),
-- fechada como as outras tabelas.
--
-- Não apaga dados. Ficam confirmados: contas com Google (o Google confirma o
-- e-mail) e contas que já criaram senha pelo link de "Esqueci minha senha"
-- (o link chegou no e-mail).
-- Espelha o modelo do Entity Framework da cardvoz-api
-- (tarefa em cardvoz-api/docs/tarefas/conta-e-senha.md).
-- =============================================================================

ALTER TABLE "Users" ADD COLUMN "EmailConfirmedAt" timestamp with time zone;

UPDATE "Users" SET "EmailConfirmedAt" = "CreatedAt" WHERE "GoogleSubject" IS NOT NULL;

UPDATE "Users" u
SET "EmailConfirmedAt" = t.primeiro
FROM (
  SELECT "UserId", min("UsedAt") AS primeiro
  FROM "PasswordResetTokens"
  WHERE "UsedAt" IS NOT NULL
  GROUP BY "UserId"
) t
WHERE u."Id" = t."UserId" AND u."EmailConfirmedAt" IS NULL;

CREATE TABLE "EmailConfirmationTokens" (
    "Id" uuid NOT NULL DEFAULT gen_random_uuid(),
    "UserId" uuid NOT NULL,
    "TokenHash" character varying(64) NOT NULL,
    "CreatedAt" timestamp with time zone NOT NULL,
    "ExpiresAt" timestamp with time zone NOT NULL,
    "UsedAt" timestamp with time zone,
    CONSTRAINT "PK_EmailConfirmationTokens" PRIMARY KEY ("Id"),
    CONSTRAINT "FK_EmailConfirmationTokens_Users_UserId" FOREIGN KEY ("UserId") REFERENCES "Users" ("Id") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_EmailConfirmationTokens_TokenHash" ON "EmailConfirmationTokens" ("TokenHash");

CREATE INDEX "IX_EmailConfirmationTokens_UserId" ON "EmailConfirmationTokens" ("UserId");

ALTER TABLE "EmailConfirmationTokens" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "EmailConfirmationTokens" FROM anon, authenticated;
