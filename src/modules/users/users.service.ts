import { PrismaClient } from '@prisma/client'
import { hashPassword, comparePassword } from '../../utils/hash'
import { CreateUserInput, UpdateUserInput, UpdateRoleInput, ChangePasswordInput } from './users.schema'

const prisma = new PrismaClient()

export async function listUsers() {
  return prisma.user.findMany({
    where: { isActive: true },
    select: {
      id: true,
      name: true,
      email: true,
      username: true,
      role: true,
      isActive: true,
      isMaster: true,
      createdAt: true,
    },
    orderBy: [{ isMaster: 'desc' }, { name: 'asc' }],
  })
}

export async function getUserById(id: string) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      name: true,
      email: true,
      username: true,
      role: true,
      isActive: true,
      createdAt: true,
      _count: { select: { orders: true } },
    },
  })
  if (!user) throw { statusCode: 404, message: 'Utilizador não encontrado' }
  return user
}

export async function createUser(data: CreateUserInput) {
  // Verificar conflito de username (sempre obrigatório)
  const existingByUsername = await (prisma as any).user.findFirst({
    where: { username: data.username },
  })

  // Verificar conflito de email (só se fornecido)
  const existingByEmail = data.email
    ? await (prisma as any).user.findFirst({ where: { email: data.email } })
    : null

  const existing = existingByUsername || existingByEmail
  const hashedPassword = await hashPassword(data.password)

  // Se já existe mas está inativo, reativa e atualiza em vez de dar erro
  if (existing) {
    if (!existing.isActive) {
      return (prisma as any).user.update({
        where: { id: existing.id },
        data: {
          name:     data.name,
          email:    data.email ?? null,
          username: data.username,
          password: hashedPassword,
          role:     data.role,
          isActive: true,
        },
        select: { id: true, name: true, email: true, username: true, role: true, isActive: true, createdAt: true },
      })
    }
    if (existingByUsername) throw { statusCode: 409, message: 'Já existe um utilizador ativo com este username' }
    throw { statusCode: 409, message: 'Já existe um utilizador ativo com este email' }
  }

  return (prisma as any).user.create({
    data: { ...data, password: hashedPassword },
    select: { id: true, name: true, email: true, username: true, role: true, isActive: true, createdAt: true },
  })
}

export async function updateUser(id: string, data: UpdateUserInput) {
  const user = await (prisma as any).user.findUnique({ where: { id } })
  if (!user) throw { statusCode: 404, message: 'Utilizador não encontrado' }

  if (data.email && data.email !== user.email) {
    const existing = await (prisma as any).user.findFirst({ where: { email: data.email } })
    if (existing) throw { statusCode: 409, message: 'Já existe um utilizador com este email' }
  }

  if (data.username && data.username !== user.username) {
    const existing = await (prisma as any).user.findFirst({ where: { username: data.username } })
    if (existing) throw { statusCode: 409, message: 'Já existe um utilizador com este username' }
  }

  return (prisma as any).user.update({
    where: { id },
    data,
    select: { id: true, name: true, email: true, username: true, role: true, isActive: true },
  })
}

export async function updateUserRole(id: string, data: UpdateRoleInput) {
  const user = await prisma.user.findUnique({ where: { id } })
  if (!user) throw { statusCode: 404, message: 'Utilizador não encontrado' }

  return prisma.user.update({
    where: { id },
    data: { role: data.role },
    select: { id: true, name: true, email: true, role: true },
  })
}

export async function deactivateUser(id: string, requestingUserId: string) {
  if (id === requestingUserId) {
    throw { statusCode: 400, message: 'Não podes desativar a tua própria conta' }
  }

  const target    = await prisma.user.findUnique({ where: { id } })
  if (!target) throw { statusCode: 404, message: 'Utilizador não encontrado' }
  if (target.isMaster) throw { statusCode: 403, message: 'A conta Master Admin não pode ser removida' }

  const requester = await prisma.user.findUnique({ where: { id: requestingUserId } })
  if (!requester?.isMaster && target.role === 'ADMIN') {
    throw { statusCode: 403, message: 'Apenas o Master Admin pode remover outros administradores' }
  }

  return prisma.user.update({
    where: { id },
    data: { isActive: false },
    select: { id: true, name: true, isActive: true },
  })
}

export async function adminResetPassword(id: string, newPassword: string, requestingUserId: string) {
  const target    = await prisma.user.findUnique({ where: { id } })
  if (!target) throw { statusCode: 404, message: 'Utilizador não encontrado' }

  const requester = await prisma.user.findUnique({ where: { id: requestingUserId } })

  // Admins normais só podem redefinir passwords de utilizadores com funções inferiores
  if (!requester?.isMaster && target.role === 'ADMIN' && id !== requestingUserId) {
    throw { statusCode: 403, message: 'Apenas o Master Admin pode redefinir a password de outros administradores' }
  }

  const hashed = await hashPassword(newPassword)
  await prisma.user.update({ where: { id }, data: { password: hashed } })
  return { message: 'Password redefinida com sucesso' }
}

export async function changePassword(id: string, data: ChangePasswordInput) {
  const user = await prisma.user.findUnique({ where: { id } })
  if (!user) throw { statusCode: 404, message: 'Utilizador não encontrado' }

  const match = await comparePassword(data.currentPassword, user.password)
  if (!match) throw { statusCode: 401, message: 'Password atual incorreta' }

  const newHash = await hashPassword(data.newPassword)
  await prisma.user.update({ where: { id }, data: { password: newHash } })

  return { message: 'Password alterada com sucesso' }
}
