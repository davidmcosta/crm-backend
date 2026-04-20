-- AddColumn: desgasteKm e combustivelKm à tabela Settings
ALTER TABLE "Settings" ADD COLUMN IF NOT EXISTS "desgasteKm" DECIMAL(10,4) NOT NULL DEFAULT 0;
ALTER TABLE "Settings" ADD COLUMN IF NOT EXISTS "combustivelKm" DECIMAL(10,4) NOT NULL DEFAULT 0;
