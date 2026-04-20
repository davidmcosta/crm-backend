-- Substituir combustivelKm (€/km) por precoCombustivel (€/litro) + consumoViatura (l/100km)
ALTER TABLE "Settings" RENAME COLUMN "combustivelKm" TO "precoCombustivel";
ALTER TABLE "Settings" ADD COLUMN IF NOT EXISTS "consumoViatura" DECIMAL(10,4) NOT NULL DEFAULT 0;
