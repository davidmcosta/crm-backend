"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listOrders = listOrders;
exports.getOrderById = getOrderById;
exports.createOrder = createOrder;
exports.updateOrder = updateOrder;
exports.updateOrderStatus = updateOrderStatus;
exports.getOrderHistory = getOrderHistory;
exports.cancelOrder = cancelOrder;
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
// ── Número de encomenda 01/26, 02/26, ... ───────────────────────────────────
async function generateOrderNumber() {
    const year = String(new Date().getFullYear()).slice(-2);
    const last = await prisma.order.findFirst({
        where: { orderNumber: { endsWith: `/${year}` } },
        orderBy: { createdAt: 'desc' },
        select: { orderNumber: true },
    });
    const next = last ? parseInt(last.orderNumber.split('/')[0], 10) + 1 : 1;
    return `${String(next).padStart(2, '0')}/${year}`;
}
// ── Listagem ─────────────────────────────────────────────────────────────────
async function listOrders(query) {
    const { page, limit, status, customerId, search, cemiterio, trabalho, produto, dateFrom, dateTo } = query;
    const skip = (page - 1) * limit;
    const where = {};
    if (status)
        where.status = status;
    if (customerId)
        where.customerId = customerId;
    // Filtros de campo específico
    if (cemiterio)
        where.cemiterio = { contains: cemiterio, mode: 'insensitive' };
    if (trabalho)
        where.trabalho = { contains: trabalho, mode: 'insensitive' };
    // Filtro por intervalo de datas
    if (dateFrom || dateTo) {
        const dateFilter = {};
        if (dateFrom)
            dateFilter['gte'] = new Date(dateFrom);
        if (dateTo) {
            const end = new Date(dateTo);
            end.setHours(23, 59, 59, 999);
            dateFilter['lte'] = end;
        }
        where.createdAt = dateFilter;
    }
    // Pesquisa de texto geral (ordem, falecido, requerente, cemitério, obs, dedicatória, cliente)
    if (search) {
        const searchOr = [
            { orderNumber: { contains: search, mode: 'insensitive' } },
            { nomeFalecido: { contains: search, mode: 'insensitive' } },
            { requerente: { contains: search, mode: 'insensitive' } },
            { cemiterio: { contains: search, mode: 'insensitive' } },
            { observacoes: { contains: search, mode: 'insensitive' } },
            { dedicatoria: { contains: search, mode: 'insensitive' } },
            { customer: { name: { contains: search, mode: 'insensitive' } } },
        ];
        where.OR = searchOr;
    }
    // Pesquisa por nome de produto (dentro do campo trabalho e também texto livre)
    if (produto) {
        const prodOr = [
            { trabalho: { contains: produto, mode: 'insensitive' } },
            { nomeFalecido: { contains: produto, mode: 'insensitive' } },
        ];
        if (where.OR) {
            // Combina com AND: (existing OR) AND (produto OR)
            where.AND = [{ OR: where.OR }, { OR: prodOr }];
            delete where.OR;
        }
        else {
            where.OR = prodOr;
        }
    }
    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where, skip, take: limit, orderBy: { createdAt: 'desc' },
            include: {
                customer: { select: { id: true, name: true, email: true } },
                createdBy: { select: { id: true, name: true } },
            },
        }),
        prisma.order.count({ where }),
    ]);
    return {
        data: orders,
        pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
}
// ── Detalhe ──────────────────────────────────────────────────────────────────
async function getOrderById(id) {
    const order = await prisma.order.findUnique({
        where: { id },
        include: {
            customer: true,
            createdBy: { select: { id: true, name: true, email: true } },
            statusHistory: {
                include: { changedBy: { select: { id: true, name: true } } },
                orderBy: { createdAt: 'desc' },
            },
        },
    });
    if (!order)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    return order;
}
// ── Criar ────────────────────────────────────────────────────────────────────
async function createOrder(data, userId) {
    if (data.customerId) {
        const customer = await prisma.customer.findUnique({ where: { id: data.customerId } });
        if (!customer)
            throw { statusCode: 404, message: 'Cliente não encontrado' };
    }
    const orderNumber = await generateOrderNumber();
    const extrasTotal = (data.extras ?? []).reduce((sum, e) => sum + e.valor, 0);
    return prisma.order.create({
        data: {
            orderNumber,
            status: client_1.OrderStatus.PENDING,
            createdById: userId,
            customerId: data.customerId ?? null,
            trabalho: data.trabalho,
            cemiterio: data.cemiterio ?? null,
            talhao: data.talhao ?? null,
            numeroSepultura: data.numeroSepultura ?? null,
            fotoPessoa: data.fotoPessoa ?? null,
            nomeFalecido: data.nomeFalecido ?? null,
            datasFalecido: data.datasFalecido ?? null,
            dedicatoria: data.dedicatoria ?? null,
            produtos: data.produtos ?? [],
            extras: data.extras ?? [],
            valorSepultura: data.valorSepultura ?? 0,
            km: data.km ?? null,
            portagens: data.portagens ?? 0,
            refeicoes: data.refeicoes ?? 0,
            deslocacaoMontagem: data.deslocacaoMontagem ?? 0,
            extrasValor: extrasTotal,
            valorTotal: data.valorTotal ?? 0,
            requerente: data.requerente,
            contacto: data.contacto,
            observacoes: data.observacoes ?? null,
            statusHistory: {
                create: { status: client_1.OrderStatus.PENDING, changedById: userId, notes: 'Encomenda criada' },
            },
        },
        include: { customer: { select: { id: true, name: true } } },
    });
}
// ── Atualizar ────────────────────────────────────────────────────────────────
async function updateOrder(id, data, userId) {
    const existing = await prisma.order.findUnique({ where: { id } });
    if (!existing)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    if (existing.status === client_1.OrderStatus.CANCELLED) {
        throw { statusCode: 400, message: 'Não é possível editar uma encomenda cancelada' };
    }
    // Recalcular extrasValor se extras for fornecido
    const updateData = { ...data, updatedAt: new Date() };
    if (data.extras !== undefined) {
        updateData.extrasValor = data.extras.reduce((sum, e) => sum + e.valor, 0);
    }
    return prisma.order.update({
        where: { id },
        data: updateData,
        include: { customer: { select: { id: true, name: true } } },
    });
}
// ── Atualizar estado ─────────────────────────────────────────────────────────
async function updateOrderStatus(id, data, userId) {
    const order = await prisma.order.findUnique({ where: { id } });
    if (!order)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    if (order.status === client_1.OrderStatus.CANCELLED)
        throw { statusCode: 400, message: 'Não é possível alterar o estado de uma encomenda cancelada' };
    if (order.status === data.status)
        throw { statusCode: 400, message: 'A encomenda já se encontra neste estado' };
    const [updated] = await prisma.$transaction([
        prisma.order.update({ where: { id }, data: { status: data.status } }),
        prisma.orderStatusHistory.create({
            data: {
                orderId: id,
                status: data.status,
                changedById: userId,
                notes: data.notes,
                fotos: data.fotos ?? [],
            },
        }),
    ]);
    return updated;
}
// ── Histórico ────────────────────────────────────────────────────────────────
async function getOrderHistory(id) {
    const order = await prisma.order.findUnique({ where: { id } });
    if (!order)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    return prisma.orderStatusHistory.findMany({
        where: { orderId: id },
        include: { changedBy: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
    });
}
// ── Cancelar ─────────────────────────────────────────────────────────────────
async function cancelOrder(id, userId) {
    const order = await prisma.order.findUnique({ where: { id } });
    if (!order)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    if (order.status === client_1.OrderStatus.CANCELLED)
        throw { statusCode: 400, message: 'A encomenda já está cancelada' };
    const [updated] = await prisma.$transaction([
        prisma.order.update({ where: { id }, data: { status: client_1.OrderStatus.CANCELLED } }),
        prisma.orderStatusHistory.create({
            data: { orderId: id, status: client_1.OrderStatus.CANCELLED, changedById: userId, notes: 'Encomenda cancelada' },
        }),
    ]);
    return updated;
}
//# sourceMappingURL=orders.service.js.map