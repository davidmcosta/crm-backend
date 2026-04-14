import { z } from 'zod'

export const loginSchema = z.object({
  login: z.string().min(1, 'Email ou utilizador é obrigatório'),
  password: z.string().min(6, 'Password deve ter pelo menos 6 caracteres'),
})

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token é obrigatório'),
})

export type LoginInput = z.infer<typeof loginSchema>
export type RefreshInput = z.infer<typeof refreshSchema>
