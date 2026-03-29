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
async function generateOrderNumber() {
    const year = new Date().getFullYear();
    const prefix = `ORD-${year}-`;
    const lastOrder = await prisma.order.findFirst({
        where: { orderNumber: { startsWith: prefix } },
        orderBy: { orderNumber: 'desc' },
        select: { orderNumber: true },
    });
    let nextNumber = 1;
    if (lastOrder) {
        const lastNum = parseInt(lastOrder.orderNumber.split('-')[2], 10);
        nextNumber = lastNum + 1;
    }
    return `${prefix}${String(nextNumber).padStart(5, '0')}`;
}
function calculateTotal(items) {
    return items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
}
async function listOrders(query) {
    const { page, limit, status, customerId, search } = query;
    const skip = (page - 1) * limit;
    const where = {};
    if (status)
        where.status = status;
    if (customerId)
        where.customerId = customerId;
    if (search) {
        where.OR = [
            { orderNumber: { contains: search, mode: 'insensitive' } },
            { customer: { name: { contains: search, mode: 'insensitive' } } },
        ];
    }
    const [orders, total] = await Promise.all([
        prisma.order.findMany({
            where, skip, take: limit, orderBy: { createdAt: 'desc' },
            include: {
                customer: { select: { id: true, name: true, email: true } },
                createdBy: { select: { id: true, name: true } },
                items: true,
                _count: { select: { items: true } },
            },
        }),
        prisma.order.count({ where }),
    ]);
    return { data: orders, pagination: { total, page, limit, totalPages: Math.ceil(total / limit) } };
}
async function getOrderById(id) {
    const order = await prisma.order.findUnique({
        where: { id },
        include: {
            customer: true,
            createdBy: { select: { id: true, name: true, email: true } },
            items: true,
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
async function createOrder(data, userId) {
    const customer = await prisma.customer.findUnique({ where: { id: data.customerId } });
    if (!customer)
        throw { statusCode: 404, message: 'Cliente não encontrado' };
    const orderNumber = await generateOrderNumber();
    const totalAmount = calculateTotal(data.items);
    return prisma.order.create({
        data: {
            orderNumber, customerId: data.customerId, createdById: userId,
            notes: data.notes,
            expectedDate: data.expectedDate ? new Date(data.expectedDate) : null,
            totalAmount, status: client_1.OrderStatus.PENDING,
            items: {
                create: data.items.map((item) => ({
                    productName: item.productName, description: item.description,
                    quantity: item.quantity, unitPrice: item.unitPrice,
                    totalPrice: item.quantity * item.unitPrice,
                })),
            },
            statusHistory: {
                create: { status: client_1.OrderStatus.PENDING, changedById: userId, notes: 'Encomenda criada' },
            },
        },
        include: { customer: { select: { id: true, name: true } }, items: true },
    });
}
async function updateOrder(id, data, userId) {
    const existing = await prisma.order.findUnique({ where: { id } });
    if (!existing)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    if (existing.status === client_1.OrderStatus.DELIVERED || existing.status === client_1.OrderStatus.CANCELLED) {
        throw { statusCode: 400, message: 'Não é possível editar uma encomenda entregue ou cancelada' };
    }
    const updateData = { notes: data.notes, updatedAt: new Date() };
    if (data.expectedDate)
        updateData.expectedDate = new Date(data.expectedDate);
    if (data.items) {
        updateData.totalAmount = calculateTotal(data.items);
        await prisma.orderItem.deleteMany({ where: { orderId: id } });
        updateData.items = {
            create: data.items.map((item) => ({
                productName: item.productName, description: item.description,
                quantity: item.quantity, unitPrice: item.unitPrice,
                totalPrice: item.quantity * item.unitPrice,
            })),
        };
    }
    return prisma.order.update({
        where: { id }, data: updateData,
        include: { items: true, customer: { select: { id: true, name: true } } },
    });
}
async function updateOrderStatus(id, data, userId) {
    const order = await prisma.order.findUnique({ where: { id } });
    if (!order)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    if (order.status === client_1.OrderStatus.CANCELLED) {
        throw { statusCode: 400, message: 'Não é possível alterar o estado de uma encomenda cancelada' };
    }
    if (order.status === data.status) {
        throw { statusCode: 400, message: 'A encomenda já se encontra neste estado' };
    }
    const [updatedOrder] = await prisma.$transaction([
        prisma.order.update({ where: { id }, data: { status: data.status } }),
        prisma.orderStatusHistory.create({
            data: { orderId: id, status: data.status, changedById: userId, notes: data.notes },
        }),
    ]);
    return updatedOrder;
}
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
async function cancelOrder(id, userId) {
    const order = await prisma.order.findUnique({ where: { id } });
    if (!order)
        throw { statusCode: 404, message: 'Encomenda não encontrada' };
    if (order.status === client_1.OrderStatus.DELIVERED) {
        throw { statusCode: 400, message: 'Não é possível cancelar uma encomenda já entregue' };
    }
    if (order.status === client_1.OrderStatus.CANCELLED) {
        throw { statusCode: 400, message: 'A encomenda já está cancelada' };
    }
    const [updatedOrder] = await prisma.$transaction([
        prisma.order.update({ where: { id }, data: { status: client_1.OrderStatus.CANCELLED } }),
        prisma.orderStatusHistory.create({
            data: { orderId: id, status: client_1.OrderStatus.CANCELLED, changedById: userId, notes: 'Encomenda cancelada' },
        }),
    ]);
    return updatedOrder;
}
//# sourceMappingURL=orders.service.js.map