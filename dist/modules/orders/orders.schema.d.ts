import { z } from 'zod';
export declare const createOrderSchema: z.ZodObject<{
    customerId: z.ZodOptional<z.ZodString>;
    trabalho: z.ZodString;
    cemiterio: z.ZodOptional<z.ZodString>;
    talhao: z.ZodOptional<z.ZodString>;
    numeroSepultura: z.ZodOptional<z.ZodString>;
    fotoPessoa: z.ZodOptional<z.ZodString>;
    nomeFalecido: z.ZodOptional<z.ZodString>;
    datasFalecido: z.ZodOptional<z.ZodString>;
    dedicatoria: z.ZodOptional<z.ZodString>;
    produtos: z.ZodDefault<z.ZodOptional<z.ZodArray<z.ZodObject<{
        nome: z.ZodString;
        qty: z.ZodNumber;
        precoUnit: z.ZodNumber;
        total: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }, {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }>, "many">>>;
    valorSepultura: z.ZodDefault<z.ZodNumber>;
    km: z.ZodOptional<z.ZodNumber>;
    portagens: z.ZodDefault<z.ZodNumber>;
    refeicoes: z.ZodDefault<z.ZodNumber>;
    deslocacaoMontagem: z.ZodDefault<z.ZodNumber>;
    extras: z.ZodDefault<z.ZodOptional<z.ZodArray<z.ZodObject<{
        descricao: z.ZodString;
        valor: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        descricao: string;
        valor: number;
    }, {
        descricao: string;
        valor: number;
    }>, "many">>>;
    extrasValor: z.ZodDefault<z.ZodNumber>;
    valorTotal: z.ZodDefault<z.ZodNumber>;
    requerente: z.ZodString;
    contacto: z.ZodString;
    observacoes: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    trabalho: string;
    produtos: {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }[];
    valorSepultura: number;
    portagens: number;
    refeicoes: number;
    deslocacaoMontagem: number;
    extras: {
        descricao: string;
        valor: number;
    }[];
    extrasValor: number;
    valorTotal: number;
    requerente: string;
    contacto: string;
    customerId?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    fotoPessoa?: string | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
    dedicatoria?: string | undefined;
    km?: number | undefined;
    observacoes?: string | undefined;
}, {
    trabalho: string;
    requerente: string;
    contacto: string;
    customerId?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    fotoPessoa?: string | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
    dedicatoria?: string | undefined;
    produtos?: {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }[] | undefined;
    valorSepultura?: number | undefined;
    km?: number | undefined;
    portagens?: number | undefined;
    refeicoes?: number | undefined;
    deslocacaoMontagem?: number | undefined;
    extras?: {
        descricao: string;
        valor: number;
    }[] | undefined;
    extrasValor?: number | undefined;
    valorTotal?: number | undefined;
    observacoes?: string | undefined;
}>;
export declare const updateOrderSchema: z.ZodObject<{
    trabalho: z.ZodOptional<z.ZodString>;
    cemiterio: z.ZodOptional<z.ZodString>;
    talhao: z.ZodOptional<z.ZodString>;
    numeroSepultura: z.ZodOptional<z.ZodString>;
    fotoPessoa: z.ZodOptional<z.ZodString>;
    nomeFalecido: z.ZodOptional<z.ZodString>;
    datasFalecido: z.ZodOptional<z.ZodString>;
    dedicatoria: z.ZodOptional<z.ZodString>;
    produtos: z.ZodOptional<z.ZodArray<z.ZodObject<{
        nome: z.ZodString;
        qty: z.ZodNumber;
        precoUnit: z.ZodNumber;
        total: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }, {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }>, "many">>;
    valorSepultura: z.ZodOptional<z.ZodNumber>;
    km: z.ZodOptional<z.ZodNumber>;
    portagens: z.ZodOptional<z.ZodNumber>;
    refeicoes: z.ZodOptional<z.ZodNumber>;
    deslocacaoMontagem: z.ZodOptional<z.ZodNumber>;
    extras: z.ZodOptional<z.ZodArray<z.ZodObject<{
        descricao: z.ZodString;
        valor: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        descricao: string;
        valor: number;
    }, {
        descricao: string;
        valor: number;
    }>, "many">>;
    extrasValor: z.ZodOptional<z.ZodNumber>;
    valorTotal: z.ZodOptional<z.ZodNumber>;
    requerente: z.ZodOptional<z.ZodString>;
    contacto: z.ZodOptional<z.ZodString>;
    observacoes: z.ZodOptional<z.ZodString>;
    customerId: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    customerId?: string | undefined;
    trabalho?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    fotoPessoa?: string | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
    dedicatoria?: string | undefined;
    produtos?: {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }[] | undefined;
    valorSepultura?: number | undefined;
    km?: number | undefined;
    portagens?: number | undefined;
    refeicoes?: number | undefined;
    deslocacaoMontagem?: number | undefined;
    extras?: {
        descricao: string;
        valor: number;
    }[] | undefined;
    extrasValor?: number | undefined;
    valorTotal?: number | undefined;
    requerente?: string | undefined;
    contacto?: string | undefined;
    observacoes?: string | undefined;
}, {
    customerId?: string | undefined;
    trabalho?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    fotoPessoa?: string | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
    dedicatoria?: string | undefined;
    produtos?: {
        nome: string;
        qty: number;
        precoUnit: number;
        total: number;
    }[] | undefined;
    valorSepultura?: number | undefined;
    km?: number | undefined;
    portagens?: number | undefined;
    refeicoes?: number | undefined;
    deslocacaoMontagem?: number | undefined;
    extras?: {
        descricao: string;
        valor: number;
    }[] | undefined;
    extrasValor?: number | undefined;
    valorTotal?: number | undefined;
    requerente?: string | undefined;
    contacto?: string | undefined;
    observacoes?: string | undefined;
}>;
export declare const updateStatusSchema: z.ZodObject<{
    status: z.ZodNativeEnum<{
        PENDING: "PENDING";
        CONFIRMED: "CONFIRMED";
        IN_PRODUCTION: "IN_PRODUCTION";
        READY: "READY";
        DELIVERED: "DELIVERED";
        CANCELLED: "CANCELLED";
    }>;
    notes: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    status: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "CANCELLED";
    notes?: string | undefined;
}, {
    status: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "CANCELLED";
    notes?: string | undefined;
}>;
export declare const listOrdersQuerySchema: z.ZodObject<{
    page: z.ZodDefault<z.ZodNumber>;
    limit: z.ZodDefault<z.ZodNumber>;
    status: z.ZodOptional<z.ZodNativeEnum<{
        PENDING: "PENDING";
        CONFIRMED: "CONFIRMED";
        IN_PRODUCTION: "IN_PRODUCTION";
        READY: "READY";
        DELIVERED: "DELIVERED";
        CANCELLED: "CANCELLED";
    }>>;
    customerId: z.ZodOptional<z.ZodString>;
    search: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    page: number;
    limit: number;
    status?: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "CANCELLED" | undefined;
    search?: string | undefined;
    customerId?: string | undefined;
}, {
    status?: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "CANCELLED" | undefined;
    search?: string | undefined;
    customerId?: string | undefined;
    page?: number | undefined;
    limit?: number | undefined;
}>;
export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type UpdateOrderInput = z.infer<typeof updateOrderSchema>;
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>;
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>;
//# sourceMappingURL=orders.schema.d.ts.map