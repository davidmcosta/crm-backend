-- Passo 1a: dar username a utilizadores sem username mas com email (usa prefixo do email)
UPDATE "User"
SET "username" = LOWER(REGEXP_REPLACE(SPLIT_PART("email", '@', 1), '[^a-zA-Z0-9._-]', '', 'g'))
WHERE "username" IS NULL AND "email" IS NOT NULL;

-- Passo 1b: dar username a utilizadores sem username e sem email (usa 1ª palavra do nome)
UPDATE "User"
SET "username" = LOWER(REGEXP_REPLACE(SPLIT_PART("name", ' ', 1), '[^a-zA-Z0-9._-]', '', 'g'))
WHERE "username" IS NULL AND ("email" IS NULL OR "username" = '');

-- Passo 1c: fallback final — usar os primeiros 8 chars do id
UPDATE "User"
SET "username" = SUBSTRING("id", 1, 8)
WHERE "username" IS NULL OR "username" = '';

-- Passo 2: garantir unicidade em caso de colisão (adiciona sufixo numérico)
DO $$
DECLARE
  r RECORD;
  cnt INT;
  base_name TEXT;
BEGIN
  FOR r IN
    SELECT id, username FROM "User" WHERE username IS NOT NULL
    ORDER BY "createdAt"
  LOOP
    cnt := 0;
    base_name := r.username;
    WHILE EXISTS (
      SELECT 1 FROM "User" WHERE username = r.username AND id != r.id
    ) LOOP
      cnt := cnt + 1;
      UPDATE "User" SET username = base_name || cnt WHERE id = r.id;
      SELECT username INTO r.username FROM "User" WHERE id = r.id;
    END LOOP;
  END LOOP;
END $$;

-- Passo 3: tornar username NOT NULL
ALTER TABLE "User" ALTER COLUMN "username" SET NOT NULL;

-- Passo 4: tornar email nullable
ALTER TABLE "User" ALTER COLUMN "email" DROP NOT NULL;
