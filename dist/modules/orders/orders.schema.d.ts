import { z } from 'zod';
export declare const createOrderSchema: z.ZodObject<{
    customerId: z.ZodString;
    trabalho: z.ZodString;
    cemiterio: z.ZodOptional<z.ZodString>;
    talhao: z.ZodOptional<z.ZodString>;
    numeroSepultura: z.ZodOptional<z.ZodString>;
    falecidos: z.ZodDefault<z.ZodOptional<z.ZodArray<z.ZodObject<{
        nome: z.ZodOptional<z.ZodString>;
        datas: z.ZodOptional<z.ZodString>;
        dedicatoria: z.ZodOptional<z.ZodString>;
        fotos: z.ZodDefault<z.ZodOptional<z.ZodArray<z.ZodString, "many">>>;
    }, "strip", z.ZodTypeAny, {
        fotos: string[];
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
    }, {
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
        fotos?: string[] | undefined;
    }>, "many">>>;
    fotoPessoa: z.ZodOptional<z.ZodString>;
    fotosPessoa: z.ZodDefault<z.ZodOptional<z.ZodArray<z.ZodString, "many">>>;
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
    requerente: z.ZodDefault<z.ZodOptional<z.ZodString>>;
    contacto: z.ZodDefault<z.ZodOptional<z.ZodString>>;
    observacoes: z.ZodOptional<z.ZodString>;
    descontoPerc: z.ZodDefault<z.ZodNumber>;
    descontoValor: z.ZodDefault<z.ZodNumber>;
    ivaPerc: z.ZodDefault<z.ZodNumber>;
    ivaValor: z.ZodDefault<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    customerId: string;
    trabalho: string;
    falecidos: {
        fotos: string[];
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
    }[];
    fotosPessoa: string[];
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
    descontoPerc: number;
    descontoValor: number;
    ivaPerc: number;
    ivaValor: number;
    dedicatoria?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    fotoPessoa?: string | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
    km?: number | undefined;
    observacoes?: string | undefined;
}, {
    customerId: string;
    trabalho: string;
    dedicatoria?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    falecidos?: {
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
        fotos?: string[] | undefined;
    }[] | undefined;
    fotoPessoa?: string | undefined;
    fotosPessoa?: string[] | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
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
    descontoPerc?: number | undefined;
    descontoValor?: number | undefined;
    ivaPerc?: number | undefined;
    ivaValor?: number | undefined;
}>;
export declare const updateOrderSchema: z.ZodObject<{
    trabalho: z.ZodOptional<z.ZodString>;
    cemiterio: z.ZodOptional<z.ZodString>;
    talhao: z.ZodOptional<z.ZodString>;
    numeroSepultura: z.ZodOptional<z.ZodString>;
    falecidos: z.ZodOptional<z.ZodArray<z.ZodObject<{
        nome: z.ZodOptional<z.ZodString>;
        datas: z.ZodOptional<z.ZodString>;
        dedicatoria: z.ZodOptional<z.ZodString>;
        fotos: z.ZodDefault<z.ZodOptional<z.ZodArray<z.ZodString, "many">>>;
    }, "strip", z.ZodTypeAny, {
        fotos: string[];
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
    }, {
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
        fotos?: string[] | undefined;
    }>, "many">>;
    fotoPessoa: z.ZodOptional<z.ZodString>;
    fotosPessoa: z.ZodOptional<z.ZodArray<z.ZodString, "many">>;
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
    descontoPerc: z.ZodOptional<z.ZodNumber>;
    descontoValor: z.ZodOptional<z.ZodNumber>;
    ivaPerc: z.ZodOptional<z.ZodNumber>;
    ivaValor: z.ZodOptional<z.ZodNumber>;
}, "strip", z.ZodTypeAny, {
    dedicatoria?: string | undefined;
    customerId?: string | undefined;
    trabalho?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    falecidos?: {
        fotos: string[];
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
    }[] | undefined;
    fotoPessoa?: string | undefined;
    fotosPessoa?: string[] | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
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
    descontoPerc?: number | undefined;
    descontoValor?: number | undefined;
    ivaPerc?: number | undefined;
    ivaValor?: number | undefined;
}, {
    dedicatoria?: string | undefined;
    customerId?: string | undefined;
    trabalho?: string | undefined;
    cemiterio?: string | undefined;
    talhao?: string | undefined;
    numeroSepultura?: string | undefined;
    falecidos?: {
        nome?: string | undefined;
        datas?: string | undefined;
        dedicatoria?: string | undefined;
        fotos?: string[] | undefined;
    }[] | undefined;
    fotoPessoa?: string | undefined;
    fotosPessoa?: string[] | undefined;
    nomeFalecido?: string | undefined;
    datasFalecido?: string | undefined;
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
    descontoPerc?: number | undefined;
    descontoValor?: number | undefined;
    ivaPerc?: number | undefined;
    ivaValor?: number | undefined;
}>;
export declare const updateStatusSchema: z.ZodObject<{
    status: z.ZodNativeEnum<{
        readonly PENDING: "PENDING";
        readonly CONFIRMED: "CONFIRMED";
        readonly IN_PRODUCTION: "IN_PRODUCTION";
        readonly READY: "READY";
        readonly DELIVERED: "DELIVERED";
        readonly PAID: "PAID";
        readonly CANCELLED: "CANCELLED";
    }>;
    notes: z.ZodOptional<z.ZodString>;
    fotos: z.ZodDefault<z.ZodOptional<z.ZodArray<z.ZodString, "many">>>;
}, "strip", z.ZodTypeAny, {
    status: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "PAID" | "CANCELLED";
    fotos: string[];
    notes?: string | undefined;
}, {
    status: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "PAID" | "CANCELLED";
    fotos?: string[] | undefined;
    notes?: string | undefined;
}>;
export declare const listOrdersQuerySchema: z.ZodObject<{
    page: z.ZodDefault<z.ZodNumber>;
    limit: z.ZodDefault<z.ZodNumber>;
    status: z.ZodOptional<z.ZodNativeEnum<{
        readonly PENDING: "PENDING";
        readonly CONFIRMED: "CONFIRMED";
        readonly IN_PRODUCTION: "IN_PRODUCTION";
        readonly READY: "READY";
        readonly DELIVERED: "DELIVERED";
        readonly PAID: "PAID";
        readonly CANCELLED: "CANCELLED";
    }>>;
    customerId: z.ZodOptional<z.ZodString>;
    search: z.ZodOptional<z.ZodString>;
    cemiterio: z.ZodOptional<z.ZodString>;
    trabalho: z.ZodOptional<z.ZodString>;
    produto: z.ZodOptional<z.ZodString>;
    dateFrom: z.ZodOptional<z.ZodString>;
    dateTo: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    page: number;
    limit: number;
    status?: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "PAID" | "CANCELLED" | undefined;
    search?: string | undefined;
    customerId?: string | undefined;
    trabalho?: string | undefined;
    cemiterio?: string | undefined;
    produto?: string | undefined;
    dateFrom?: string | undefined;
    dateTo?: string | undefined;
}, {
    status?: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "DELIVERED" | "PAID" | "CANCELLED" | undefined;
    search?: string | undefined;
    customerId?: string | undefined;
    trabalho?: string | undefined;
    cemiterio?: string | undefined;
    page?: number | undefined;
    limit?: number | undefined;
    produto?: string | undefined;
    dateFrom?: string | undefined;
    dateTo?: string | undefined;
}>;
export type CreateOrderInput = z.infer<typeof createOrderSchema>;
export type UpdateOrderInput = z.infer<typeof updateOrderSchema>;
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>;
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>;
//# sourceMappingURL=orders.schema.d.ts.map