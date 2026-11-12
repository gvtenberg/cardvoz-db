-- =============================================================================
-- CardVoz - acertos e erros de cada ficha
--
-- A cliente pediu para o CardVoz guardar quantas vezes ela acertou e errou e
-- para estudar só as fichas que errou. Cada resposta já fica em
-- "StudyReviews"; estas colunas guardam o resumo na própria ficha, para a API
-- devolvê-lo junto com o baralho sem somar o histórico inteiro a cada leitura.
--
-- "Cards":
-- - "CorrectCount" e "IncorrectCount": quantas vezes a ficha foi respondida
--   com "Acertei" e com "Errei".
-- - "LastAnsweredAt" e "LastWasCorrect": a resposta mais recente. É ela que
--   decide se a ficha entra em "Estudar só as que errei". Nulo = nunca estudada.
--
-- "Decks":
-- - "LastStudiedAt": quando o baralho foi estudado pela última vez. O site
--   compara esse valor para saber que precisa buscar os números novos (estudar
--   não muda o "UpdatedAt" do baralho).
--
-- Não apaga dados: as colunas novas nascem com zero ou nulas e são preenchidas
-- com o histórico que já existe em "StudyReviews".
-- Espelha o modelo do Entity Framework da cardvoz-api
-- (tarefa em cardvoz-api/docs/tarefas/estatisticas-das-fichas.md).
-- =============================================================================

ALTER TABLE "Cards" ADD COLUMN "CorrectCount" integer NOT NULL DEFAULT 0;

ALTER TABLE "Cards" ADD COLUMN "IncorrectCount" integer NOT NULL DEFAULT 0;

ALTER TABLE "Cards" ADD COLUMN "LastAnsweredAt" timestamp with time zone;

ALTER TABLE "Cards" ADD COLUMN "LastWasCorrect" boolean;

ALTER TABLE "Cards" ADD CONSTRAINT "CK_Cards_CorrectCount" CHECK ("CorrectCount" >= 0);

ALTER TABLE "Cards" ADD CONSTRAINT "CK_Cards_IncorrectCount" CHECK ("IncorrectCount" >= 0);

ALTER TABLE "Decks" ADD COLUMN "LastStudiedAt" timestamp with time zone;

-- Preenche com o histórico que já existe
UPDATE "Cards" c
SET "CorrectCount" = s.correct,
    "IncorrectCount" = s.incorrect,
    "LastAnsweredAt" = s.last_at,
    "LastWasCorrect" = s.last_correct
FROM (
  SELECT r."CardId",
         count(*) FILTER (WHERE r."WasCorrect") AS correct,
         count(*) FILTER (WHERE NOT r."WasCorrect") AS incorrect,
         max(r."AnsweredAt") AS last_at,
         (array_agg(r."WasCorrect" ORDER BY r."AnsweredAt" DESC))[1] AS last_correct
  FROM "StudyReviews" r
  GROUP BY r."CardId"
) s
WHERE c."Id" = s."CardId";

-- A mais recente entre o fim das sessões e as respostas (sessão sem fim
-- registrado ainda tem respostas depois do início)
UPDATE "Decks" d
SET "LastStudiedAt" = s.last_at
FROM (
  SELECT ss."DeckId",
         greatest(max(coalesce(ss."CompletedAt", ss."StartedAt")), max(r."AnsweredAt")) AS last_at
  FROM "StudySessions" ss
  LEFT JOIN "StudyReviews" r ON r."StudySessionId" = ss."Id"
  GROUP BY ss."DeckId"
) s
WHERE d."Id" = s."DeckId";
