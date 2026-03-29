import { CreateOrderInput, UpdateOrderInput, UpdateStatusInput, ListOrdersQuery } from './orders.schema';
export declare function listOrders(query: ListOrdersQuery): Promise<{
    data: ({
        _count: {
            items: number;
        };
        items: {
            id: string;
            createdAt: Date;
            productName: string;
            description: string | null;
            quantity: number;
            unitPrice: import("@prisma/client/runtime/library").Decimal;
            orderId: string;
            totalPrice: import("@prisma/client/runtime/library").Decimal;
        }[];
        customer: {
            email: string | null;
            id: string;
            name: string;
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
    })[];
    pagination: {
        total: number;
        page: number;
        limit: number;
        totalPages: number;
    };
}>;
export declare function getOrderById(id: string): Promise<{
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
        orderId: string;
        changedById: string;
    })[];
    items: {
        id: string;
        createdAt: Date;
        productName: string;
        description: string | null;
        quantity: number;
        unitPrice: import("@prisma/client/runtime/library").Decimal;
        orderId: string;
        totalPrice: import("@prisma/client/runtime/library").Decimal;
    }[];
    customer: {
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
    };
    createdBy: {
        email: string;
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
}>;
export declare function createOrder(data: CreateOrderInput, userId: string): Promise<{
    items: {
        id: string;
        createdAt: Date;
        productName: string;
        description: string | null;
        quantity: number;
        unitPrice: import("@prisma/client/runtime/library").Decimal;
        orderId: string;
        totalPrice: import("@prisma/client/runtime/library").Decimal;
    }[];
    customer: {
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
}>;
export declare function updateOrder(id: string, data: UpdateOrderInput, userId: string): Promise<{
    items: {
        id: string;
        createdAt: Date;
        productName: string;
        description: string | null;
        quantity: number;
        unitPrice: import("@prisma/client/runtime/library").Decimal;
        orderId: string;
        totalPrice: import("@prisma/client/runtime/library").Decimal;
    }[];
    customer: {
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
}>;
export declare function updateOrderStatus(id: string, data: UpdateStatusInput, userId: string): Promise<{
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
    orderId: string;
    changedById: string;
})[]>;
export declare function cancelOrder(id: string, userId: string): Promise<{
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
}>;
//# sourceMappingURL=orders.service.d.ts.map