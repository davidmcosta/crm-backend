/*
  Warnings:

  - You are about to drop the column `isActive` on the `Customer` table. All the data in the column will be lost.
  - You are about to drop the column `isActive` on the `User` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Customer" DROP COLUMN "isActive",
ADD COLUMN     "active" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "taxId" TEXT;

-- AlterTable
ALTER TABLE "User" DROP COLUMN "isActive",
ADD COLUMN     "active" BOOLEAN NOT NULL DEFAULT true;
