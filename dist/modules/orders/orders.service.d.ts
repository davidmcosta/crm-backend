import { CreateOrderInput, UpdateOrderInput, UpdateStatusInput, ListOrdersQuery } from './orders.schema';
export declare function listOrders(query: ListOrdersQuery): Promise<{
    data: ({
        customer: {
            email: string | null;
            id: string;
            name: string;
        } | null;
        createdBy: {
            id: string;
            name: string;
        };
    } & {
        status: import(".prisma/client").$Enums.OrderStatus;
        id: string;
        createdAt: Date;
        updatedAt: Date;
        customerId: string | null;
        trabalho: string;
        cemiterio: string | null;
        talhao: string | null;
        numeroSepultura: string | null;
        fotoPessoa: string | null;
        nomeFalecido: string | null;
        datasFalecido: string | null;
        dedicatoria: string | null;
        produtos: import("@prisma/client/runtime/library").JsonValue;
        valorSepultura: import("@prisma/client/runtime/library").Decimal;
        km: number | null;
        portagens: import("@prisma/client/runtime/library").Decimal;
        refeicoes: import("@prisma/client/runtime/library").Decimal;
        deslocacaoMontagem: import("@prisma/client/runtime/library").Decimal;
        extras: import("@prisma/client/runtime/library").JsonValue;
        extrasValor: import("@prisma/client/runtime/library").Decimal;
        valorTotal: import("@prisma/client/runtime/library").Decimal;
        requerente: string;
        contacto: string;
        observacoes: string | null;
        orderNumber: string;
        extrasDescricao: string | null;
        createdById: string;
    })[];
    pagination: {
        total: number;
        page: number;
        limit: number;
        totalPages: number;
    };
}>;
export declare function getOrderById(id: string): Promise<{
    customer: {
        email: string | null;
        id: string;
        name: string;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        notes: string | null;
        phone: string | null;
        address: string | null;
    } | null;
    createdBy: {
        email: string;
        id: string;
        name: string;
    };
    statusHistory: ({
        changedBy: {
            id: string;
            name: string;
        };
    } & {
        status: import(".prisma/client").$Enums.OrderStatus;
        id: string;
        createdAt: Date;
        notes: string | null;
        fotos: import("@prisma/client/runtime/library").JsonValue;
        changedById: string;
        orderId: string;
    })[];
} & {
    status: import(".prisma/client").$Enums.OrderStatus;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    customerId: string | null;
    trabalho: string;
    cemiterio: string | null;
    talhao: string | null;
    numeroSepultura: string | null;
    fotoPessoa: string | null;
    nomeFalecido: string | null;
    datasFalecido: string | null;
    dedicatoria: string | null;
    produtos: import("@prisma/client/runtime/library").JsonValue;
    valorSepultura: import("@prisma/client/runtime/library").Decimal;
    km: number | null;
    portagens: import("@prisma/client/runtime/library").Decimal;
    refeicoes: import("@prisma/client/runtime/library").Decimal;
    deslocacaoMontagem: import("@prisma/client/runtime/library").Decimal;
    extras: import("@prisma/client/runtime/library").JsonValue;
    extrasValor: import("@prisma/client/runtime/library").Decimal;
    valorTotal: import("@prisma/client/runtime/library").Decimal;
    requerente: string;
    contacto: string;
    observacoes: string | null;
    orderNumber: string;
    extrasDescricao: string | null;
    createdById: string;
}>;
export declare function createOrder(data: CreateOrderInput, userId: string): Promise<{
    customer: {
        id: string;
        name: string;
    } | null;
} & {
    status: import(".prisma/client").$Enums.OrderStatus;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    customerId: string | null;
    trabalho: string;
    cemiterio: string | null;
    talhao: string | null;
    numeroSepultura: string | null;
    fotoPessoa: string | null;
    nomeFalecido: string | null;
    datasFalecido: string | null;
    dedicatoria: string | null;
    produtos: import("@prisma/client/runtime/library").JsonValue;
    valorSepultura: import("@prisma/client/runtime/library").Decimal;
    km: number | null;
    portagens: import("@prisma/client/runtime/library").Decimal;
    refeicoes: import("@prisma/client/runtime/library").Decimal;
    deslocacaoMontagem: import("@prisma/client/runtime/library").Decimal;
    extras: import("@prisma/client/runtime/library").JsonValue;
    extrasValor: import("@prisma/client/runtime/library").Decimal;
    valorTotal: import("@prisma/client/runtime/library").Decimal;
    requerente: string;
    contacto: string;
    observacoes: string | null;
    orderNumber: string;
    extrasDescricao: string | null;
    createdById: string;
}>;
export declare function updateOrder(id: string, data: UpdateOrderInput, userId: string): Promise<{
    customer: {
        id: string;
        name: string;
    } | null;
} & {
    status: import(".prisma/client").$Enums.OrderStatus;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    customerId: string | null;
    trabalho: string;
    cemiterio: string | null;
    talhao: string | null;
    numeroSepultura: string | null;
    fotoPessoa: string | null;
    nomeFalecido: string | null;
    datasFalecido: string | null;
    dedicatoria: string | null;
    produtos: import("@prisma/client/runtime/library").JsonValue;
    valorSepultura: import("@prisma/client/runtime/library").Decimal;
    km: number | null;
    portagens: import("@prisma/client/runtime/library").Decimal;
    refeicoes: import("@prisma/client/runtime/library").Decimal;
    deslocacaoMontagem: import("@prisma/client/runtime/library").Decimal;
    extras: import("@prisma/client/runtime/library").JsonValue;
    extrasValor: import("@prisma/client/runtime/library").Decimal;
    valorTotal: import("@prisma/client/runtime/library").Decimal;
    requerente: string;
    contacto: string;
    observacoes: string | null;
    orderNumber: string;
    extrasDescricao: string | null;
    createdById: string;
}>;
export declare function updateOrderStatus(id: string, data: UpdateStatusInput, userId: string): Promise<{
    status: import(".prisma/client").$Enums.OrderStatus;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    customerId: string | null;
    trabalho: string;
    cemiterio: string | null;
    talhao: string | null;
    numeroSepultura: string | null;
    fotoPessoa: string | null;
    nomeFalecido: string | null;
    datasFalecido: string | null;
    dedicatoria: string | null;
    produtos: import("@prisma/client/runtime/library").JsonValue;
    valorSepultura: import("@prisma/client/runtime/library").Decimal;
    km: number | null;
    portagens: import("@prisma/client/runtime/library").Decimal;
    refeicoes: import("@prisma/client/runtime/library").Decimal;
    deslocacaoMontagem: import("@prisma/client/runtime/library").Decimal;
    extras: import("@prisma/client/runtime/library").JsonValue;
    extrasValor: import("@prisma/client/runtime/library").Decimal;
    valorTotal: import("@prisma/client/runtime/library").Decimal;
    requerente: string;
    contacto: string;
    observacoes: string | null;
    orderNumber: string;
    extrasDescricao: string | null;
    createdById: string;
}>;
export declare function getOrderHistory(id: string): Promise<({
    changedBy: {
        id: string;
        name: string;
    };
} & {
    status: import(".prisma/client").$Enums.OrderStatus;
    id: string;
    createdAt: Date;
    notes: string | null;
    fotos: import("@prisma/client/runtime/library").JsonValue;
    changedById: string;
    orderId: string;
})[]>;
export declare function cancelOrder(id: string, userId: string): Promise<{
    status: import(".prisma/client").$Enums.OrderStatus;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    customerId: string | null;
    trabalho: string;
    cemiterio: string | null;
    talhao: string | null;
    numeroSepultura: string | null;
    fotoPessoa: string | null;
    nomeFalecido: string | null;
    datasFalecido: string | null;
    dedicatoria: string | null;
    produtos: import("@prisma/client/runtime/library").JsonValue;
    valorSepultura: import("@prisma/client/runtime/library").Decimal;
    km: number | null;
    portagens: import("@prisma/client/runtime/library").Decimal;
    refeicoes: import("@prisma/client/runtime/library").Decimal;
    deslocacaoMontagem: import("@prisma/client/runtime/library").Decimal;
    extras: import("@prisma/client/runtime/library").JsonValue;
    extrasValor: import("@prisma/client/runtime/library").Decimal;
    valorTotal: import("@prisma/client/runtime/library").Decimal;
    requerente: string;
    contacto: string;
    observacoes: string | null;
    orderNumber: string;
    extrasDescricao: string | null;
    createdById: string;
}>;
//# sourceMappingURL=orders.service.d.ts.map