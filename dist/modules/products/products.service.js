"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listProducts = listProducts;
exports.getProductById = getProductById;
exports.createProduct = createProduct;
exports.updateProduct = updateProduct;
exports.deleteProduct = deleteProduct;
exports.listCategories = listCategories;
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
// ── Listagem ─────────────────────────────────────────────────────────────────
async function listProducts(query) {
    const { category, search, active } = query;
    const where = {};
    if (category)
        where.category = { contains: category, mode: 'insensitive' };
    if (active !== undefined)
        where.isActive = active === 'true';
    if (search) {
        where.OR = [
            { name: { contains: search, mode: 'insensitive' } },
            { category: { contains: search, mode: 'insensitive' } },
            { description: { contains: search, mode: 'insensitive' } },
        ];
    }
    return prisma.product.findMany({
        where,
        include: { bomItems: { orderBy: { sortOrder: 'asc' } } },
        orderBy: [{ category: 'asc' }, { name: 'asc' }],
    });
}
// ── Detalhe ──────────────────────────────────────────────────────────────────
async function getProductById(id) {
    const product = await prisma.product.findUnique({
        where: { id },
        include: { bomItems: { orderBy: { sortOrder: 'asc' } } },
    });
    if (!product)
        throw { statusCode: 404, message: 'Produto não encontrado' };
    return product;
}
// ── Criar ────────────────────────────────────────────────────────────────────
async function createProduct(data) {
    const { bomItems, ...rest } = data;
    return prisma.product.create({
        data: {
            ...rest,
            bomItems: {
                create: bomItems.map((item, i) => ({ ...item, sortOrder: i })),
            },
        },
        include: { bomItems: { orderBy: { sortOrder: 'asc' } } },
    });
}
// ── Atualizar ────────────────────────────────────────────────────────────────
async function updateProduct(id, data) {
    const existing = await prisma.product.findUnique({ where: { id } });
    if (!existing)
        throw { statusCode: 404, message: 'Produto não encontrado' };
    const { bomItems, ...rest } = data;
    return prisma.$transaction(async (tx) => {
        // Replace BOM items if provided
        if (bomItems !== undefined) {
            await tx.productBOM.deleteMany({ where: { productId: id } });
            if (bomItems.length > 0) {
                await tx.productBOM.createMany({
                    data: bomItems.map((item, i) => ({
                        productId: id,
                        componentName: item.componentName,
                        qty: item.qty ?? 1,
                        includedPrice: item.includedPrice ?? 0,
                        sortOrder: i,
                    })),
                });
            }
        }
        return tx.product.update({
            where: { id },
            data: { ...rest, updatedAt: new Date() },
            include: { bomItems: { orderBy: { sortOrder: 'asc' } } },
        });
    });
}
// ── Eliminar ─────────────────────────────────────────────────────────────────
async function deleteProduct(id) {
    const existing = await prisma.product.findUnique({ where: { id } });
    if (!existing)
        throw { statusCode: 404, message: 'Produto não encontrado' };
    await prisma.product.delete({ where: { id } });
    return { success: true };
}
// ── Categorias disponíveis ────────────────────────────────────────────────────
async function listCategories() {
    const products = await prisma.product.findMany({
        select: { category: true },
        where: { category: { not: null } },
        distinct: ['category'],
        orderBy: { category: 'asc' },
    });
    return products.map((p) => p.category).filter(Boolean);
}
//# sourceMappingURL=products.service.js.map