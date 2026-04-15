/**
 * Enums locais que espelham os enums do Prisma schema.
 * Usar estes em vez de importar de @prisma/client evita erros de compilação
 * quando o cliente Prisma ainda não foi regenerado.
 */

export const UserRole = {
  ADMIN:    'ADMIN',
  MANAGER:  'MANAGER',
  OPERATOR: 'OPERATOR',
  VIEWER:   'VIEWER',
} as const
export type UserRole = typeof UserRole[keyof typeof UserRole]

export const OrderStatus = {
  PENDING:       'PENDING',
  CONFIRMED:     'CONFIRMED',
  IN_PRODUCTION: 'IN_PRODUCTION',
  READY:         'READY',
  DELIVERED:     'DELIVERED',
  PAID:          'PAID',
  CANCELLED:     'CANCELLED',
} as const
export type OrderStatus = typeof OrderStatus[keyof typeof OrderStatus]
