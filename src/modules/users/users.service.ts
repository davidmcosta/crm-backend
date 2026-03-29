import { PrismaClient } from '@prisma/client'
import { hashPassword, comparePassword } from '../../utils/hash'
import { CreateUserInput, UpdateUserInput, UpdateRoleInput, ChangePasswordInput } from './users.schema'

const prisma = new PrismaClient()

export async function listUsers() {
  return prisma.user.findMany({
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
      active: true,
      createdAt: true,
    },
    orderBy: { name: 'asc' },
  })
}

export async function getUserById(id: string) {
  const user = await prisma.user.findUnique({
    where: { id },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
      active: true,
      createdAt: true,
      _count: { select: { orders: true } },
    },
  })
  if (!user) throw { statusCode: 404, message: 'Utilizador não encontrado' }
  return user
}

export async function createUser(data: CreateUserInput) {
  const existing = await prisma.user.findUnique({ where: { email: data.email } })
  if (existing) throw { statusCode: 409, message: 'Já existe um utilizador com este email' }

  const hashedPassword = await hashPassword(data.password)
  return prisma.user.create({
    data: { ...data, password: hashedPassword },
    select: { id: true, name: true, email: true, role: true, active: true, createdAt: true },
  })
}

export async function updateUser(id: string, data: UpdateUserInput) {
  const user = await prisma.user.findUnique({ where: { id } })
  if (!user) throw { statusCode: 404, message: 'Utilizador não encontrado' }

  if (data.email && data.email !== user.email) {
    const existing = await prisma.user.findUnique({ where: { email: data.email } })
    if (existing) throw { statusCode: 409, message: 'Já existe um utilizador com este email' }
  }

  return prisma.user.update({
    where: { id },
    data,
    select: { id: true, name: true, email: true, role: true, active: true },
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

  const user = await prisma.user.findUnique({ where: { id } })
  if (!user) throw { statusCode: 404, message: 'Utilizador não encontrado' }

  return prisma.user.update({
    where: { id },
    data: { active: false },
    select: { id: true, name: true, active: true },
  })
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
