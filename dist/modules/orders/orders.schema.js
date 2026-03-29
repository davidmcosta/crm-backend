"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listOrdersQuerySchema = exports.updateStatusSchema = exports.updateOrderSchema = exports.createOrderSchema = void 0;
const zod_1 = require("zod");
const client_1 = require("@prisma/client");
const orderItemSchema = zod_1.z.object({
    productName: zod_1.z.string().min(1, 'Nome do produto é obrigatório'),
    description: zod_1.z.string().optional(),
    quantity: zod_1.z.number().int().positive('Quantidade deve ser positiva'),
    unitPrice: zod_1.z.number().positive('Preço unitário deve ser positivo'),
});
exports.createOrderSchema = zod_1.z.object({
    customerId: zod_1.z.string().uuid('ID do cliente inválido'),
    notes: zod_1.z.string().optional(),
    expectedDate: zod_1.z.string().datetime().optional(),
    items: zod_1.z.array(orderItemSchema).min(1, 'A encomenda deve ter pelo menos 1 item'),
});
exports.updateOrderSchema = zod_1.z.object({
    notes: zod_1.z.string().optional(),
    expectedDate: zod_1.z.string().datetime().optional(),
    items: zod_1.z.array(orderItemSchema).min(1).optional(),
});
exports.updateStatusSchema = zod_1.z.object({
    status: zod_1.z.nativeEnum(client_1.OrderStatus, { errorMap: () => ({ message: 'Estado inválido' }) }),
    notes: zod_1.z.string().optional(),
});
exports.listOrdersQuerySchema = zod_1.z.object({
    page: zod_1.z.coerce.number().int().positive().default(1),
    limit: zod_1.z.coerce.number().int().positive().max(100).default(20),
    status: zod_1.z.nativeEnum(client_1.OrderStatus).optional(),
    customerId: zod_1.z.string().uuid().optional(),
    search: zod_1.z.string().optional(),
});
//# sourceMappingURL=orders.schema.js.map