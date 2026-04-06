-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "dedicatoria" TEXT,
ADD COLUMN     "extras" JSONB NOT NULL DEFAULT '[]';
