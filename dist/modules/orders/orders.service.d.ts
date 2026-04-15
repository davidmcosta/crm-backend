import { CreateOrderInput, UpdateOrderInput, UpdateStatusInput, ListOrdersQuery } from './orders.schema';
export declare function listOrders(query: ListOrdersQuery): Promise<{
    data: any;
    pagination: {
        total: any;
        page: number;
        limit: number;
        totalPages: number;
    };
}>;
export declare function getOrderById(id: string): Promise<any>;
export declare function createOrder(data: CreateOrderInput, userId: string): Promise<any>;
export declare function updateOrder(id: string, data: UpdateOrderInput, userId: string): Promise<any>;
export declare function updateOrderStatus(id: string, data: UpdateStatusInput, userId: string): Promise<any>;
export declare function getOrderHistory(id: string): Promise<any>;
export declare function cancelOrder(id: string, userId: string): Promise<any>;
export declare function deleteOrder(id: string): Promise<{
    success: boolean;
}>;
//# sourceMappingURL=orders.service.d.ts.map