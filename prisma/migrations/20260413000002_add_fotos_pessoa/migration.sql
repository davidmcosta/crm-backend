-- Add fotosPessoa array field to Order table
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "fotosPessoa" JSONB NOT NULL DEFAULT '[]';
