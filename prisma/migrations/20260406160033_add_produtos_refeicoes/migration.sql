/*
  Warnings:

  - The values [SHIPPED] on the enum `OrderStatus` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `active` on the `Customer` table. All the data in the column will be lost.
  - You are about to drop the column `taxId` on the `Customer` table. All the data in the column will be lost.
  - You are about to drop the column `active` on the `User` table. All the data in the column will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "OrderStatus_new" AS ENUM ('PENDING', 'CONFIRMED', 'IN_PRODUCTION', 'READY', 'DELIVERED', 'CANCELLED');
ALTER TABLE "Order" ALTER COLUMN "status" DROP DEFAULT;
ALTER TABLE "Order" ALTER COLUMN "status" TYPE "OrderStatus_new" USING ("status"::text::"OrderStatus_new");
ALTER TABLE "OrderStatusHistory" ALTER COLUMN "status" TYPE "OrderStatus_new" USING ("status"::text::"OrderStatus_new");
ALTER TYPE "OrderStatus" RENAME TO "OrderStatus_old";
ALTER TYPE "OrderStatus_new" RENAME TO "OrderStatus";
DROP TYPE "OrderStatus_old";
ALTER TABLE "Order" ALTER COLUMN "status" SET DEFAULT 'PENDING';
COMMIT;

-- AlterTable
ALTER TABLE "Customer" DROP COLUMN "active",
DROP COLUMN "taxId",
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "produtos" JSONB NOT NULL DEFAULT '[]',
ADD COLUMN     "refeicoes" DECIMAL(10,2) NOT NULL DEFAULT 0,
ALTER COLUMN "nomeFalecido" DROP NOT NULL;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "active",
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true;
