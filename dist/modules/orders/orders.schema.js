"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listOrdersQuerySchema = exports.updateStatusSchema = exports.updateOrderSchema = exports.createOrderSchema = void 0;
const zod_1 = require("zod");
const client_1 = require("@prisma/client");
exports.createOrderSchema = zod_1.z.object({
    // Cliente (opcional)
    customerId: zod_1.z.string().optional(),
    // Trabalho
    trabalho: zod_1.z.string().min(1, 'Trabalho é obrigatório'),
    // Cemitério
    cemiterio: zod_1.z.string().optional(),
    talhao: zod_1.z.string().optional(),
    numeroSepultura: zod_1.z.string().optional(),
    // Falecido
    fotoPessoa: zod_1.z.string().optional(), // base64 data URL
    nomeFalecido: zod_1.z.string().min(1, 'Nome do falecido é obrigatório'),
    datasFalecido: zod_1.z.string().optional(), // ex: "01/01/1950 - 15/03/2026"
    // Valores financeiros
    valorSepultura: zod_1.z.number().min(0).default(0),
    km: zod_1.z.number().min(0).optional(),
    portagens: zod_1.z.number().min(0).default(0),
    deslocacaoMontagem: zod_1.z.number().min(0).default(0),
    extrasDescricao: zod_1.z.string().optional(),
    extrasValor: zod_1.z.number().min(0).default(0),
    valorTotal: zod_1.z.number().min(0).default(0),
    // Requerente
    requerente: zod_1.z.string().min(1, 'Requerente é obrigatório'),
    contacto: zod_1.z.string().min(1, 'Contacto é obrigatório'),
    observacoes: zod_1.z.string().optional(),
});
exports.updateOrderSchema = zod_1.z.object({
    trabalho: zod_1.z.string().min(1).optional(),
    cemiterio: zod_1.z.string().optional(),
    talhao: zod_1.z.string().optional(),
    numeroSepultura: zod_1.z.string().optional(),
    fotoPessoa: zod_1.z.string().optional(),
    nomeFalecido: zod_1.z.string().min(1).optional(),
    datasFalecido: zod_1.z.string().optional(),
    valorSepultura: zod_1.z.number().min(0).optional(),
    km: zod_1.z.number().min(0).optional(),
    portagens: zod_1.z.number().min(0).optional(),
    deslocacaoMontagem: zod_1.z.number().min(0).optional(),
    extrasDescricao: zod_1.z.string().optional(),
    extrasValor: zod_1.z.number().min(0).optional(),
    valorTotal: zod_1.z.number().min(0).optional(),
    requerente: zod_1.z.string().min(1).optional(),
    contacto: zod_1.z.string().min(1).optional(),
    observacoes: zod_1.z.string().optional(),
    customerId: zod_1.z.string().optional(),
});
exports.updateStatusSchema = zod_1.z.object({
    status: zod_1.z.nativeEnum(client_1.OrderStatus, { errorMap: () => ({ message: 'Estado inválido' }) }),
    notes: zod_1.z.string().optional(),
});
exports.listOrdersQuerySchema = zod_1.z.object({
    page: zod_1.z.coerce.number().int().positive().default(1),
    limit: zod_1.z.coerce.number().int().positive().max(100).default(20),
    status: zod_1.z.nativeEnum(client_1.OrderStatus).optional(),
    customerId: zod_1.z.string().optional(),
    search: zod_1.z.string().optional(),
});
//# sourceMappingURL=orders.schema.js.map