import { PrismaClient } from '@prisma/client'
import { CreateProductInput, UpdateProductInput, ListProductsQuery } from './products.schema'

const prisma = new PrismaClient() as any

// ── Listagem ─────────────────────────────────────────────────────────────────
export async function listProducts(query: ListProductsQuery) {
  const { category, search, active } = query
  const where: any = {}

  if (category) where.category = { contains: category, mode: 'insensitive' }
  if (active !== undefined) where.isActive = active === 'true'
  if (search) {
    where.OR = [
      { name:        { contains: search, mode: 'insensitive' } },
      { category:    { contains: search, mode: 'insensitive' } },
      { description: { contains: search, mode: 'insensitive' } },
    ]
  }

  return prisma.product.findMany({
    where,
    include: { bomItems: { orderBy: { sortOrder: 'asc' }, include: { componentProduct: { select: { id: true, name: true, basePrice: true } } } } },
    orderBy: [{ category: 'asc' }, { name: 'asc' }],
  })
}

// ── Detalhe ──────────────────────────────────────────────────────────────────
export async function getProductById(id: string) {
  const product = await prisma.product.findUnique({
    where: { id },
    include: { bomItems: { orderBy: { sortOrder: 'asc' }, include: { componentProduct: { select: { id: true, name: true, basePrice: true } } } } },
  })
  if (!product) throw { statusCode: 404, message: 'Produto não encontrado' }
  return product
}

// ── Criar ────────────────────────────────────────────────────────────────────
export async function createProduct(data: CreateProductInput) {
  const { bomItems, ...rest } = data
  return prisma.product.create({
    data: {
      ...rest,
      bomItems: {
        create: bomItems.map((item, i) => ({
          componentProductId: item.componentProductId ?? null,
          componentName:      item.componentName,
          qty:                item.qty          ?? 1,
          includedPrice:      item.includedPrice ?? 0,
          sortOrder:          i,
        })),
      },
    },
    include: { bomItems: { orderBy: { sortOrder: 'asc' }, include: { componentProduct: { select: { id: true, name: true, basePrice: true } } } } },
  })
}

// ── Atualizar ────────────────────────────────────────────────────────────────
export async function updateProduct(id: string, data: UpdateProductInput) {
  const existing = await prisma.product.findUnique({ where: { id } })
  if (!existing) throw { statusCode: 404, message: 'Produto não encontrado' }

  const { bomItems, ...rest } = data

  return prisma.$transaction(async (tx: any) => {
    // Replace BOM items if provided
    if (bomItems !== undefined) {
      await tx.productBOM.deleteMany({ where: { productId: id } })
      if (bomItems.length > 0) {
        await tx.productBOM.createMany({
          data: bomItems.map((item, i) => ({
            productId:          id,
            componentProductId: item.componentProductId ?? null,
            componentName:      item.componentName,
            qty:                item.qty          ?? 1,
            includedPrice:      item.includedPrice ?? 0,
            sortOrder:          i,
          })),
        })
      }
    }

    return tx.product.update({
      where: { id },
      data:  { ...rest, updatedAt: new Date() },
      include: { bomItems: { orderBy: { sortOrder: 'asc' }, include: { componentProduct: { select: { id: true, name: true, basePrice: true } } } } },
    })
  })
}

// ── Eliminar ─────────────────────────────────────────────────────────────────
export async function deleteProduct(id: string) {
  const existing = await prisma.product.findUnique({ where: { id } })
  if (!existing) throw { statusCode: 404, message: 'Produto não encontrado' }
  await prisma.product.delete({ where: { id } })
  return { success: true }
}

// ── Categorias disponíveis ────────────────────────────────────────────────────
export async function listCategories() {
  const products = await prisma.product.findMany({
    select: { category: true },
    where:  { category: { not: null } },
    distinct: ['category'],
    orderBy: { category: 'asc' },
  })
  return products.map((p: any) => p.category).filter(Boolean)
}
