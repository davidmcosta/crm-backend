import { z } from 'zod'
import { UserRole } from '../../types/enums'

export const createUserSchema = z.object({
  name:     z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
  email:    z.string().email('Email inválido').optional().nullable(),
  username: z.string().min(3, 'Username deve ter pelo menos 3 caracteres').max(30),
  password: z.string().min(8, 'Password deve ter pelo menos 8 caracteres'),
  role:     z.nativeEnum(UserRole).default(UserRole.OPERATOR),
})

export const updateUserSchema = z.object({
  name:     z.string().min(2).optional(),
  email:    z.string().email().optional().nullable(),
  username: z.string().min(3).max(30).optional(),
})

export const updateRoleSchema = z.object({
  role: z.nativeEnum(UserRole, { errorMap: () => ({ message: 'Perfil inválido' }) }),
})

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Password atual é obrigatória'),
  newPassword: z.string().min(8, 'Nova password deve ter pelo menos 8 caracteres'),
})

export type CreateUserInput = z.infer<typeof createUserSchema>
export type UpdateUserInput = z.infer<typeof updateUserSchema>
export type UpdateRoleInput = z.infer<typeof updateRoleSchema>
export type ChangePasswordInput = z.infer<typeof changePasswordSchema>
