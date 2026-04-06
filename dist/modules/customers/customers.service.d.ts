import { CreateCustomerInput, UpdateCustomerInput, ListCustomersQuery } from './customers.schema';
export declare function listCustomers(query: ListCustomersQuery): Promise<{
    data: ({
        _count: {
            orders: number;
        };
    } & {
        email: string | null;
        id: string;
        name: string;
        isActive: boolean;
        createdAt: Date;
        updatedAt: Date;
        notes: string | null;
        phone: string | null;
        address: string | null;
    })[];
    pagination: {
        total: number;
        page: number;
        limit: number;
        totalPages: number;
    };
}>;
export declare function getCustomerById(id: string): Promise<{
    _count: {
        orders: number;
    };
} & {
    email: string | null;
    id: string;
    name: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    notes: string | null;
    phone: string | null;
    address: string | null;
}>;
export declare function getCustomerOrders(id: string): Promise<({
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
})[]>;
export declare function createCustomer(data: CreateCustomerInput): Promise<{
    email: string | null;
    id: string;
    name: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    notes: string | null;
    phone: string | null;
    address: string | null;
}>;
export declare function updateCustomer(id: string, data: UpdateCustomerInput): Promise<{
    email: string | null;
    id: string;
    name: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
    notes: string | null;
    phone: string | null;
    address: string | null;
}>;
//# sourceMappingURL=customers.service.d.ts.map