"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listOrdersQuerySchema = exports.updateStatusSchema = exports.updateOrderSchema = exports.createOrderSchema = void 0;
const zod_1 = require("zod");
const client_1 = require("@prisma/client");
const produtoSchema = zod_1.z.object({
    nome: zod_1.z.string().min(1),
    qty: zod_1.z.number().positive(),
    precoUnit: zod_1.z.number().min(0),
    total: zod_1.z.number().min(0),
});
const extraSchema = zod_1.z.object({
    descricao: zod_1.z.string().min(1),
    valor: zod_1.z.number().min(0),
});
exports.createOrderSchema = zod_1.z.object({
    customerId: zod_1.z.string().optional(),
    // Trabalho
    trabalho: zod_1.z.string().min(1, 'Trabalho é obrigatório'),
    // Cemitério
    cemiterio: zod_1.z.string().optional(),
    talhao: zod_1.z.string().optional(),
    numeroSepultura: zod_1.z.string().optional(),
    // Falecido (todos opcionais)
    fotoPessoa: zod_1.z.string().optional(),
    nomeFalecido: zod_1.z.string().optional(),
    datasFalecido: zod_1.z.string().optional(),
    dedicatoria: zod_1.z.string().optional(),
    // Produtos (lista dinâmica)
    produtos: zod_1.z.array(produtoSchema).optional().default([]),
    // Valores financeiros
    valorSepultura: zod_1.z.number().min(0).default(0),
    km: zod_1.z.number().min(0).optional(),
    portagens: zod_1.z.number().min(0).default(0),
    refeicoes: zod_1.z.number().min(0).default(0),
    deslocacaoMontagem: zod_1.z.number().min(0).default(0),
    // Extras (lista dinâmica)
    extras: zod_1.z.array(extraSchema).optional().default([]),
    // mantidos para compatibilidade retroactiva — calculados no service
    extrasValor: zod_1.z.number().min(0).default(0),
    valorTotal: zod_1.z.number().min(0).default(0),
    // Requerente
    requerente: zod_1.z.string().min(1, 'Requerente é obrigatório'),
    contacto: zod_1.z.string().min(1, 'Contacto é obrigatório'),
    observacoes: zod_1.z.string().optional(),
    descontoPerc: zod_1.z.number().min(0).max(100).default(0),
    descontoValor: zod_1.z.number().min(0).default(0),
    ivaPerc: zod_1.z.number().min(0).max(100).default(0),
    ivaValor: zod_1.z.number().min(0).default(0),
});
exports.updateOrderSchema = zod_1.z.object({
    trabalho: zod_1.z.string().min(1).optional(),
    cemiterio: zod_1.z.string().optional(),
    talhao: zod_1.z.string().optional(),
    numeroSepultura: zod_1.z.string().optional(),
    fotoPessoa: zod_1.z.string().optional(),
    nomeFalecido: zod_1.z.string().optional(),
    datasFalecido: zod_1.z.string().optional(),
    dedicatoria: zod_1.z.string().optional(),
    produtos: zod_1.z.array(produtoSchema).optional(),
    valorSepultura: zod_1.z.number().min(0).optional(),
    km: zod_1.z.number().min(0).optional(),
    portagens: zod_1.z.number().min(0).optional(),
    refeicoes: zod_1.z.number().min(0).optional(),
    deslocacaoMontagem: zod_1.z.number().min(0).optional(),
    extras: zod_1.z.array(extraSchema).optional(),
    extrasValor: zod_1.z.number().min(0).optional(),
    valorTotal: zod_1.z.number().min(0).optional(),
    requerente: zod_1.z.string().min(1).optional(),
    contacto: zod_1.z.string().min(1).optional(),
    observacoes: zod_1.z.string().optional(),
    customerId: zod_1.z.string().optional(),
    descontoPerc: zod_1.z.number().min(0).max(100).optional(),
    descontoValor: zod_1.z.number().min(0).optional(),
    ivaPerc: zod_1.z.number().min(0).max(100).optional(),
    ivaValor: zod_1.z.number().min(0).optional(),
});
exports.updateStatusSchema = zod_1.z.object({
    status: zod_1.z.nativeEnum(client_1.OrderStatus, { errorMap: () => ({ message: 'Estado inválido' }) }),
    notes: zod_1.z.string().optional(),
    fotos: zod_1.z.array(zod_1.z.string()).optional().default([]),
});
exports.listOrdersQuerySchema = zod_1.z.object({
    page: zod_1.z.coerce.number().int().positive().default(1),
    limit: zod_1.z.coerce.number().int().positive().max(100).default(20),
    status: zod_1.z.nativeEnum(client_1.OrderStatus).optional(),
    customerId: zod_1.z.string().optional(),
    search: zod_1.z.string().optional(),
    cemiterio: zod_1.z.string().optional(),
    trabalho: zod_1.z.string().optional(),
    produto: zod_1.z.string().optional(),
    dateFrom: zod_1.z.string().optional(),
    dateTo: zod_1.z.string().optional(),
});
//# sourceMappingURL=orders.schema.js.map