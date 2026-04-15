"use strict";
/**
 * Enums locais que espelham os enums do Prisma schema.
 * Usar estes em vez de importar de @prisma/client evita erros de compilação
 * quando o cliente Prisma ainda não foi regenerado.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.OrderStatus = exports.UserRole = void 0;
exports.UserRole = {
    ADMIN: 'ADMIN',
    MANAGER: 'MANAGER',
    OPERATOR: 'OPERATOR',
    VIEWER: 'VIEWER',
};
exports.OrderStatus = {
    PENDING: 'PENDING',
    CONFIRMED: 'CONFIRMED',
    IN_PRODUCTION: 'IN_PRODUCTION',
    READY: 'READY',
    DELIVERED: 'DELIVERED',
    PAID: 'PAID',
    CANCELLED: 'CANCELLED',
};
//# sourceMappingURL=enums.js.map