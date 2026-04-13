import { z } from 'zod'

const bomItemSchema = z.object({
  componentName: z.string().min(1),
  qty:           z.number().positive().default(1),
  includedPrice: z.number().min(0).default(0),
  sortOrder:     z.number().int().default(0),
})

export const createProductSchema = z.object({
  name:        z.string().min(1),
  category:    z.string().optional(),
  description: z.string().optional(),
  basePrice:   z.number().min(0).default(0),
  isActive:    z.boolean().default(true),
  bomItems:    z.array(bomItemSchema).default([]),
})

export const updateProductSchema = createProductSchema.partial()

export const listProductsQuerySchema = z.object({
  category: z.string().optional(),
  search:   z.string().optional(),
  active:   z.enum(['true', 'false']).optional(),
})

export type CreateProductInput  = z.infer<typeof createProductSchema>
export type UpdateProductInput  = z.infer<typeof updateProductSchema>
export type ListProductsQuery   = z.infer<typeof listProductsQuerySchema>
