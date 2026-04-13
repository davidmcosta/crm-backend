-- Add falecidos JSON array to Order table
ALTER TABLE "Order" ADD COLUMN IF NOT EXISTS "falecidos" JSONB NOT NULL DEFAULT '[]';
