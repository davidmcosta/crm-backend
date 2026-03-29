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
        active: boolean;
        createdAt: Date;
        updatedAt: Date;
        notes: string | null;
        phone: string | null;
        address: string | null;
        taxId: string | null;
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
    active: boolean;
    createdAt: Date;
    updatedAt: Date;
    notes: string | null;
    phone: string | null;
    address: string | null;
    taxId: string | null;
}>;
export declare function getCustomerOrders(id: string): Promise<({
    _count: {
        items: number;
    };
    createdBy: {
        id: string;
        name: string;
    };
} & {
    status: import(".prisma/client").$Enums.OrderStatus;
    id: string;
    createdAt: Date;
    updatedAt: Date;
    customerId: string;
    notes: string | null;
    expectedDate: Date | null;
    orderNumber: string;
    createdById: string;
    totalAmount: import("@prisma/client/runtime/library").Decimal;
})[]>;
export declare function createCustomer(data: CreateCustomerInput): Promise<{
    email: string | null;
    id: string;
    name: string;
    active: boolean;
    createdAt: Date;
    updatedAt: Date;
    notes: string | null;
    phone: string | null;
    address: string | null;
    taxId: string | null;
}>;
export declare function updateCustomer(id: string, data: UpdateCustomerInput): Promise<{
    email: string | null;
    id: string;
    name: string;
    active: boolean;
    createdAt: Date;
    updatedAt: Date;
    notes: string | null;
    phone: string | null;
    address: string | null;
    taxId: string | null;
}>;
//# sourceMappingURL=customers.service.d.ts.map