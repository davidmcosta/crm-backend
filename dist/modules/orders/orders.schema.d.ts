import { z } from 'zod';
export declare const createOrderSchema: z.ZodObject<{
    customerId: z.ZodString;
    notes: z.ZodOptional<z.ZodString>;
    expectedDate: z.ZodOptional<z.ZodString>;
    items: z.ZodArray<z.ZodObject<{
        productName: z.ZodString;
        description: z.ZodOptional<z.ZodString>;
        quantity: z.ZodNumber;
        unitPrice: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }, {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }>, "many">;
}, "strip", z.ZodTypeAny, {
    customerId: string;
    items: {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }[];
    notes?: string | undefined;
    expectedDate?: string | undefined;
}, {
    customerId: string;
    items: {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }[];
    notes?: string | undefined;
    expectedDate?: string | undefined;
}>;
export declare const updateOrderSchema: z.ZodObject<{
    notes: z.ZodOptional<z.ZodString>;
    expectedDate: z.ZodOptional<z.ZodString>;
    items: z.ZodOptional<z.ZodArray<z.ZodObject<{
        productName: z.ZodString;
        description: z.ZodOptional<z.ZodString>;
        quantity: z.ZodNumber;
        unitPrice: z.ZodNumber;
    }, "strip", z.ZodTypeAny, {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }, {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }>, "many">>;
}, "strip", z.ZodTypeAny, {
    notes?: string | undefined;
    expectedDate?: string | undefined;
    items?: {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }[] | undefined;
}, {
    notes?: string | undefined;
    expectedDate?: string | undefined;
    items?: {
        productName: string;
        quantity: number;
        unitPrice: number;
        description?: string | undefined;
    }[] | undefined;
}>;
export declare const updateStatusSchema: z.ZodObject<{
    status: z.ZodNativeEnum<{
        PENDING: "PENDING";
        CONFIRMED: "CONFIRMED";
        IN_PRODUCTION: "IN_PRODUCTION";
        READY: "READY";
        SHIPPED: "SHIPPED";
        DELIVERED: "DELIVERED";
        CANCELLED: "CANCELLED";
    }>;
    notes: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    status: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "SHIPPED" | "DELIVERED" | "CANCELLED";
    notes?: string | undefined;
}, {
    status: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "SHIPPED" | "DELIVERED" | "CANCELLED";
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
        SHIPPED: "SHIPPED";
        DELIVERED: "DELIVERED";
        CANCELLED: "CANCELLED";
    }>>;
    customerId: z.ZodOptional<z.ZodString>;
    search: z.ZodOptional<z.ZodString>;
}, "strip", z.ZodTypeAny, {
    page: number;
    limit: number;
    status?: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "SHIPPED" | "DELIVERED" | "CANCELLED" | undefined;
    search?: string | undefined;
    customerId?: string | undefined;
}, {
    status?: "PENDING" | "CONFIRMED" | "IN_PRODUCTION" | "READY" | "SHIPPED" | "DELIVERED" | "CANCELLED" | undefined;
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