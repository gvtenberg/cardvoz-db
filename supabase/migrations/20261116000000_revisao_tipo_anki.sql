-- =============================================================================
-- CardVoz - revisão espaçada no estilo do Anki (algoritmo SM-2)
--
-- A caixa de Leitner tinha 7 níveis com esperas fixas (1 dia, 3 dias, 1 semana...
-- até 3 meses), iguais para todas as fichas. Agora cada ficha tem o próprio ritmo:
-- - "Acertei" numa ficha nova ou errada marca a revisão para daqui a 1 dia;
-- - "Acertei" numa ficha em revisão multiplica o intervalo pela facilidade da
--   ficha (começa em 2,5: 1 dia, 3 dias, 8 dias, 20 dias, 50 dias... até 1 ano);
-- - "Errei" volta a ficha para revisar na hora e, se ela já estava em revisão,
--   baixa a facilidade em 0,2 (mínimo 1,3): a ficha difícil volta mais vezes.
--
-- "Cards":
-- - "ReviewEase": facilidade em milésimos (2500 = 2,5), de 1300 a 2500.
-- - O intervalo da ficha não ganha coluna: são os dias entre "LastAnsweredAt" e
--   "NextReviewAt", que já existem. Assim ele não diverge das datas, e as fichas
--   já estudadas continuam de onde estavam na caixa de Leitner.
--
-- A regra fica na API (Card.RecordAnswer) e, igual, no site (src/lib/studyStats.ts,
-- para funcionar sem internet).
--
-- Não apaga dados nem muda as fichas: a facilidade de todas começa em 2,5.
--
-- "ReviewLevel" continua na tabela, sem uso pela API nova: a API publicada ainda
-- lê e grava essa coluna enquanto a nova não entra no ar (e pode continuar
-- funcionando depois desta migration). Uma migration futura pode removê-la.
-- =============================================================================

ALTER TABLE "Cards" ADD COLUMN "ReviewEase" smallint NOT NULL DEFAULT 2500;

ALTER TABLE "Cards" ADD CONSTRAINT "CK_Cards_ReviewEase" CHECK ("ReviewEase" BETWEEN 1300 AND 2500);
