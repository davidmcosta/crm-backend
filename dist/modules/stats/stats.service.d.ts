export declare function getStats(): Promise<{
    summary: {
        totalOrders: number;
        ordersThisYear: number;
        ordersThisMonth: number;
        revenueThisYear: number;
        revenueThisMonth: number;
        totalRevenue: number;
        avgOrderValue: number;
        paidCount: number;
        pendingCount: number;
        cancelledCount: number;
    };
    ordersByMonth: {
        key: string;
        label: string;
        count: number;
        revenue: number;
    }[];
    ordersByStatus: Record<string, number>;
    topCustomers: {
        name: string;
        count: number;
        revenue: number;
    }[];
    topProducts: {
        name: string;
        qty: number;
        revenue: number;
    }[];
    ordersByWork: {
        name: string;
        count: number;
    }[];
}>;
//# sourceMappingURL=stats.service.d.ts.map