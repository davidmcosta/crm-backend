/**
 * Enums locais que espelham os enums do Prisma schema.
 * Usar estes em vez de importar de @prisma/client evita erros de compilação
 * quando o cliente Prisma ainda não foi regenerado.
 */
export declare const UserRole: {
    readonly ADMIN: "ADMIN";
    readonly MANAGER: "MANAGER";
    readonly OPERATOR: "OPERATOR";
    readonly VIEWER: "VIEWER";
};
export type UserRole = typeof UserRole[keyof typeof UserRole];
export declare const OrderStatus: {
    readonly PENDING: "PENDING";
    readonly CONFIRMED: "CONFIRMED";
    readonly IN_PRODUCTION: "IN_PRODUCTION";
    readonly READY: "READY";
    readonly DELIVERED: "DELIVERED";
    readonly PAID: "PAID";
    readonly CANCELLED: "CANCELLED";
};
export type OrderStatus = typeof OrderStatus[keyof typeof OrderStatus];
//# sourceMappingURL=enums.d.ts.map