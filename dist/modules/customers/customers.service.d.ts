import { CreateCustomerInput, UpdateCustomerInput, ListCustomersQuery } from './customers.schema';
export declare function listCustomers(query: ListCustomersQuery): Promise<{
    data: any;
    pagination: {
        total: any;
        page: number;
        limit: number;
        totalPages: number;
    };
}>;
export declare function getCustomerById(id: string): Promise<any>;
export declare function getCustomerOrders(id: string): Promise<any>;
export declare function createCustomer(data: CreateCustomerInput): Promise<any>;
export declare function updateCustomer(id: string, data: UpdateCustomerInput): Promise<any>;
export declare function deleteCustomer(id: string): Promise<{
    message: string;
    ordersAffected: any;
}>;
//# sourceMappingURL=customers.service.d.ts.map