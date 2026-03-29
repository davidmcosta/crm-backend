import { z } from 'zod'

export const createCustomerSchema = z.object({
  name: z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
  email: z.string().email('Email inválido').optional().or(z.literal('')),
  phone: z.string().optional(),
  address: z.string().optional(),
  taxId: z.string().optional(),
  notes: z.string().optional(),
})

export const updateCustomerSchema = createCustomerSchema.partial()

export const listCustomersQuerySchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
  search: z.string().optional(),
})

export type CreateCustomerInput = z.infer<typeof createCustomerSchema>
export type UpdateCustomerInput = z.infer<typeof updateCustomerSchema>
export type ListCustomersQuery = z.infer<typeof listCustomersQuerySchema>
