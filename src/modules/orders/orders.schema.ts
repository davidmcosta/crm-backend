import { z } from 'zod'
import { OrderStatus } from '@prisma/client'

export const createOrderSchema = z.object({
  // Cliente (opcional)
  customerId: z.string().optional(),

  // Trabalho
  trabalho: z.string().min(1, 'Trabalho é obrigatório'),

  // Cemitério
  cemiterio: z.string().optional(),
  talhao: z.string().optional(),
  numeroSepultura: z.string().optional(),

  // Falecido
  fotoPessoa: z.string().optional(),       // base64 data URL
  nomeFalecido: z.string().min(1, 'Nome do falecido é obrigatório'),
  datasFalecido: z.string().optional(),     // ex: "01/01/1950 - 15/03/2026"

  // Valores financeiros
  valorSepultura: z.number().min(0).default(0),
  km: z.number().min(0).optional(),
  portagens: z.number().min(0).default(0),
  deslocacaoMontagem: z.number().min(0).default(0),
  extrasDescricao: z.string().optional(),
  extrasValor: z.number().min(0).default(0),
  valorTotal: z.number().min(0).default(0),

  // Requerente
  requerente: z.string().min(1, 'Requerente é obrigatório'),
  contacto: z.string().min(1, 'Contacto é obrigatório'),
  observacoes: z.string().optional(),
})

export const updateOrderSchema = z.object({
  trabalho: z.string().min(1).optional(),
  cemiterio: z.string().optional(),
  talhao: z.string().optional(),
  numeroSepultura: z.string().optional(),
  fotoPessoa: z.string().optional(),
  nomeFalecido: z.string().min(1).optional(),
  datasFalecido: z.string().optional(),
  valorSepultura: z.number().min(0).optional(),
  km: z.number().min(0).optional(),
  portagens: z.number().min(0).optional(),
  deslocacaoMontagem: z.number().min(0).optional(),
  extrasDescricao: z.string().optional(),
  extrasValor: z.number().min(0).optional(),
  valorTotal: z.number().min(0).optional(),
  requerente: z.string().min(1).optional(),
  contacto: z.string().min(1).optional(),
  observacoes: z.string().optional(),
  customerId: z.string().optional(),
})

export const updateStatusSchema = z.object({
  status: z.nativeEnum(OrderStatus, { errorMap: () => ({ message: 'Estado inválido' }) }),
  notes: z.string().optional(),
})

export const listOrdersQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  status: z.nativeEnum(OrderStatus).optional(),
  customerId: z.string().optional(),
  search: z.string().optional(),
})

export type CreateOrderInput = z.infer<typeof createOrderSchema>
export type UpdateOrderInput = z.infer<typeof updateOrderSchema>
export type UpdateStatusInput = z.infer<typeof updateStatusSchema>
export type ListOrdersQuery = z.infer<typeof listOrdersQuerySchema>
