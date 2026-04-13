import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient() as any

export async function getSettings() {
  let settings = await prisma.settings.findUnique({ where: { id: 'global' } })
  if (!settings) {
    settings = await prisma.settings.create({
      data: { id: 'global', anoAtual: 0, kmRate: 0.36, mealCost: 12 },
    })
  }
  return settings
}

export async function updateSettings(data: {
  anoAtual?: number
  kmRate?:   number
  mealCost?: number
}) {
  return prisma.settings.upsert({
    where:  { id: 'global' },
    create: { id: 'global', anoAtual: 0, kmRate: 0.36, mealCost: 12, ...data },
    update: { ...data, updatedAt: new Date() },
  })
}
