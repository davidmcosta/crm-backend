import { z } from 'zod'
import { OrderStatus } from '@prisma/client'

const orderItemSchema = z.object({
  productName: z.string().min(1, 'Nome do produto é obrigatório'),
  description: z.string().optional(),
  quantity: z.number().int().positive('Quantidade deve ser positiva'),
  unitPrice: z.number().positive('Preço unitário deve ser positivo'),
})

export const createOrderSchema = z.object({
  customerId: z.string().min(1, 'Cliente é obrigatório'),
  notes: z.string().optional(),
  expectedDate: z.string().datetime().optional(),
  items: z.array(orderItemSchema).min(1, 'A encomenda deve ter pelo menos 1 item'),
})

export const updateOrderSchema = z.object({
  notes: z.string().optional(),
  expectedDate: z.string().datetime().optional(),
  items: z.array(orderItemSchema).min(1).optional(),
})

export const updateStatusSchema = z.object({
  status: z.nativeEnum(OrderStatus, { errorMap: () => ({ message: 'Estado inválido' }) }),
  notes: z.string().optional(),
})

export const listOrdersQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  status: z.nativeEnum(OrderStatus).optional(),
  customerId: z.string().uuid().optional(),
  search: z.string().optional(),
})

export type CreateOrderInput = z.infer<typeof createOrderSchema>
export type UpdateOrderInput = z.infer<typeof updateOrderSchema>
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>
