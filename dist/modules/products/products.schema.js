"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listProductsQuerySchema = exports.updateProductSchema = exports.createProductSchema = void 0;
const zod_1 = require("zod");
const bomItemSchema = zod_1.z.object({
    componentName: zod_1.z.string().min(1),
    qty: zod_1.z.number().positive().default(1),
    includedPrice: zod_1.z.number().min(0).default(0),
    sortOrder: zod_1.z.number().int().default(0),
});
exports.createProductSchema = zod_1.z.object({
    name: zod_1.z.string().min(1),
    category: zod_1.z.string().optional(),
    description: zod_1.z.string().optional(),
    basePrice: zod_1.z.number().min(0).default(0),
    isActive: zod_1.z.boolean().default(true),
    bomItems: zod_1.z.array(bomItemSchema).default([]),
});
exports.updateProductSchema = exports.createProductSchema.partial();
exports.listProductsQuerySchema = zod_1.z.object({
    category: zod_1.z.string().optional(),
    search: zod_1.z.string().optional(),
    active: zod_1.z.enum(['true', 'false']).optional(),
});
//# sourceMappingURL=products.schema.js.map