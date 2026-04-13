-- Products catalog
CREATE TABLE IF NOT EXISTS "Product" (
  "id"          TEXT NOT NULL,
  "name"        TEXT NOT NULL,
  "category"    TEXT,
  "description" TEXT,
  "basePrice"   DECIMAL(10,2) NOT NULL DEFAULT 0,
  "isActive"    BOOLEAN NOT NULL DEFAULT true,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);

CREATE TABLE IF NOT EXISTS "ProductBOM" (
  "id"            TEXT NOT NULL,
  "productId"     TEXT NOT NULL,
  "componentName" TEXT NOT NULL,
  "qty"           DOUBLE PRECISION NOT NULL DEFAULT 1,
  "includedPrice" DECIMAL(10,2) NOT NULL DEFAULT 0,
  "sortOrder"     INTEGER NOT NULL DEFAULT 0,
  "createdAt"     TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "ProductBOM_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "ProductBOM_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- Settings singleton
CREATE TABLE IF NOT EXISTS "Settings" (
  "id"        TEXT NOT NULL DEFAULT 'global',
  "anoAtual"  INTEGER NOT NULL DEFAULT 0,
  "kmRate"    DECIMAL(10,4) NOT NULL DEFAULT 0.36,
  "mealCost"  DECIMAL(10,2) NOT NULL DEFAULT 12,
  "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "Settings_pkey" PRIMARY KEY ("id")
);

INSERT INTO "Settings" ("id", "anoAtual", "kmRate", "mealCost", "updatedAt")
VALUES ('global', 0, 0.36, 12, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;
