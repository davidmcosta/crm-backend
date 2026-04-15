-- Passo 1: Atribuir usernames temporários únicos a utilizadores sem username
-- (baseados no id, garantem ausência de colisão com qualquer valor existente)
UPDATE "User"
SET "username" = '_tmp_' || SUBSTRING("id", 1, 8)
WHERE "username" IS NULL;

-- Passo 2: Substituir os usernames temporários pelos nomes desejados,
-- processando um de cada vez por ordem de criação para gerir colisões
DO $$
DECLARE
  r          RECORD;
  desired    TEXT;
  base_name  TEXT;
  cnt        INT;
BEGIN
  FOR r IN
    SELECT id, email, name FROM "User"
    WHERE username LIKE '_tmp_%'
    ORDER BY "createdAt"
  LOOP
    -- Derivar username desejado: prefixo do email > 1ª palavra do nome > 8 chars do id
    base_name := COALESCE(
      NULLIF(LOWER(REGEXP_REPLACE(SPLIT_PART(COALESCE(r.email, ''), '@', 1), '[^a-zA-Z0-9._-]', '', 'g')), ''),
      NULLIF(LOWER(REGEXP_REPLACE(SPLIT_PART(r.name, ' ', 1), '[^a-zA-Z0-9._-]', '', 'g')), ''),
      SUBSTRING(r.id, 1, 8)
    );

    desired := base_name;
    cnt     := 0;

    -- Enquanto o username já existir (em qualquer utilizador), adicionar sufixo numérico
    WHILE EXISTS (SELECT 1 FROM "User" WHERE username = desired) LOOP
      cnt     := cnt + 1;
      desired := base_name || cnt;
    END LOOP;

    UPDATE "User" SET username = desired WHERE id = r.id;
  END LOOP;
END $$;

-- Passo 3: Tornar username NOT NULL
ALTER TABLE "User" ALTER COLUMN "username" SET NOT NULL;

-- Passo 4: Tornar email nullable
ALTER TABLE "User" ALTER COLUMN "email" DROP NOT NULL;
