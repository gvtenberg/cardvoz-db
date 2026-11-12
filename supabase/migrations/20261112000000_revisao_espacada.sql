-- =============================================================================
-- CardVoz - revisão espaçada (caixa de Leitner)
--
-- A cliente pediu para o CardVoz dizer quais fichas revisar depois de horas,
-- dias, semanas e meses. Cada ficha fica numa "caixa" (nível de 0 a 6):
-- - "Errei" volta a ficha para o nível 0, para revisar na hora;
-- - "Acertei" sobe um nível, e a próxima revisão fica para daqui a
--   1 dia (nível 1), 3 dias (2), 1 semana (3), 2 semanas (4), 1 mês (5)
--   ou 3 meses (6, o máximo).
--
-- "Cards":
-- - "ReviewLevel": o nível (0 a 6).
-- - "NextReviewAt": quando a ficha volta para "Revisar agora". Nulo = ficha
--   nunca estudada (ela aparece em "Estudar", não em "Revisar agora").
--
-- A regra fica na API (Card.RecordAnswer) e, igual, no site (para funcionar
-- sem internet).
--
-- Não apaga dados: o nível de cada ficha estudada é o número de acertos
-- seguidos desde o último erro (até 6), calculado com "StudyReviews"; a
-- próxima revisão conta a partir da última resposta.
-- Espelha o modelo do Entity Framework da cardvoz-api
-- (tarefa em cardvoz-api/docs/tarefas/revisao-espacada.md).
-- =============================================================================

ALTER TABLE "Cards" ADD COLUMN "ReviewLevel" smallint NOT NULL DEFAULT 0;

ALTER TABLE "Cards" ADD COLUMN "NextReviewAt" timestamp with time zone;

ALTER TABLE "Cards" ADD CONSTRAINT "CK_Cards_ReviewLevel" CHECK ("ReviewLevel" BETWEEN 0 AND 6);

-- Acertos seguidos desde o último erro, por ficha
WITH ultimos AS (
  SELECT r."CardId",
         count(*) FILTER (
           WHERE r."WasCorrect"
             AND r."AnsweredAt" > coalesce(e.ultimo_erro, '-infinity'::timestamptz)
         ) AS seguidos
  FROM "StudyReviews" r
  LEFT JOIN (
    SELECT "CardId", max("AnsweredAt") AS ultimo_erro
    FROM "StudyReviews"
    WHERE NOT "WasCorrect"
    GROUP BY "CardId"
  ) e ON e."CardId" = r."CardId"
  GROUP BY r."CardId"
)
UPDATE "Cards" c
SET "ReviewLevel" = least(u.seguidos, 6)
FROM ultimos u
WHERE c."Id" = u."CardId";

-- Fichas com resposta registrada (inclusive as que vieram do aparelho sem histórico em "StudyReviews")
UPDATE "Cards"
SET "ReviewLevel" = CASE WHEN "LastWasCorrect" THEN greatest("ReviewLevel", 1) ELSE 0 END,
    "NextReviewAt" = "LastAnsweredAt" + CASE
      WHEN NOT "LastWasCorrect" THEN interval '0'
      ELSE CASE least(greatest("ReviewLevel", 1), 6)
        WHEN 1 THEN interval '1 day'
        WHEN 2 THEN interval '3 days'
        WHEN 3 THEN interval '7 days'
        WHEN 4 THEN interval '14 days'
        WHEN 5 THEN interval '30 days'
        ELSE interval '90 days'
      END
    END
WHERE "LastAnsweredAt" IS NOT NULL AND "LastWasCorrect" IS NOT NULL;
