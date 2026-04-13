"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listCustomersQuerySchema = exports.updateCustomerSchema = exports.createCustomerSchema = void 0;
const zod_1 = require("zod");
exports.createCustomerSchema = zod_1.z.object({
    name: zod_1.z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
    email: zod_1.z.string().email('Email inválido').optional().or(zod_1.z.literal('')),
    phone: zod_1.z.string().optional(),
    address: zod_1.z.string().optional(),
    taxId: zod_1.z.string().optional(),
    notes: zod_1.z.string().optional(),
    discount: zod_1.z.coerce.number().min(0).max(100).default(0),
});
exports.updateCustomerSchema = exports.createCustomerSchema.partial();
exports.listCustomersQuerySchema = zod_1.z.object({
    page: zod_1.z.coerce.number().int().positive().default(1),
    limit: zod_1.z.coerce.number().int().positive().max(100).default(20),
    search: zod_1.z.string().optional(),
});
//# sourceMappingURL=customers.schema.js.map