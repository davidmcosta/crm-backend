"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listCustomers = listCustomers;
exports.getCustomerById = getCustomerById;
exports.getCustomerOrders = getCustomerOrders;
exports.createCustomer = createCustomer;
exports.updateCustomer = updateCustomer;
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function listCustomers(query) {
    const { page, limit, search } = query;
    const skip = (page - 1) * limit;
    const where = { isActive: true };
    if (search) {
        where.OR = [
            { name: { contains: search, mode: 'insensitive' } },
            { email: { contains: search, mode: 'insensitive' } },
            { phone: { contains: search, mode: 'insensitive' } },
            { taxId: { contains: search, mode: 'insensitive' } },
        ];
    }
    const [customers, total] = await Promise.all([
        prisma.customer.findMany({
            where,
            skip,
            take: limit,
            orderBy: { name: 'asc' },
            include: { _count: { select: { orders: true } } },
        }),
        prisma.customer.count({ where }),
    ]);
    return {
        data: customers,
        pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
}
async function getCustomerById(id) {
    const customer = await prisma.customer.findUnique({
        where: { id },
        include: { _count: { select: { orders: true } } },
    });
    if (!customer || !customer.isActive) {
        throw { statusCode: 404, message: 'Cliente não encontrado' };
    }
    return customer;
}
async function getCustomerOrders(id) {
    const customer = await prisma.customer.findUnique({ where: { id } });
    if (!customer)
        throw { statusCode: 404, message: 'Cliente não encontrado' };
    return prisma.order.findMany({
        where: { customerId: id },
        orderBy: { createdAt: 'desc' },
        include: {
            createdBy: { select: { id: true, name: true } },
        },
    });
}
async function createCustomer(data) {
    return prisma.customer.create({ data });
}
async function updateCustomer(id, data) {
    const customer = await prisma.customer.findUnique({ where: { id } });
    if (!customer || !customer.isActive) {
        throw { statusCode: 404, message: 'Cliente não encontrado' };
    }
    return prisma.customer.update({ where: { id }, data });
}
//# sourceMappingURL=customers.service.js.map