import { PrismaClient } from '@prisma/client'
import { FastifyInstance } from 'fastify'
import { comparePassword } from '../../utils/hash'
import { env } from '../../config/env'
import { LoginInput } from './auth.schema'

const prisma = new PrismaClient()

export async function loginService(app: FastifyInstance, data: LoginInput) {
  const user = await prisma.user.findUnique({
    where: { email: data.email },
    select: {
      id: true,
      name: true,
      email: true,
      password: true,
      role: true,
      isActive: true,
    },
  })

  if (!user || !user.isActive) {
    throw { statusCode: 401, message: 'Credenciais inválidas' }
  }

  const passwordMatch = await comparePassword(data.password, user.password)
  if (!passwordMatch) {
    throw { statusCode: 401, message: 'Credenciais inválidas' }
  }

  const payload = { id: user.id, email: user.email, role: user.role }

  const accessToken = app.jwt.sign(payload, {
    expiresIn: env.JWT_EXPIRES_IN,
  })

  // Refresh token com secret diferente e validade maior
  const refreshToken = app.jwt.sign(
    { id: user.id, type: 'refresh' },
    { expiresIn: env.JWT_REFRESH_EXPIRES_IN }
  )

  return {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    },
  }
}

export async function refreshTokenService(app: FastifyInstance, refreshToken: string) {
  let payload: { id: string; type: string }

  try {
    payload = app.jwt.verify(refreshToken) as { id: string; type: string }
  } catch {
    throw { statusCode: 401, message: 'Refresh token inválido ou expirado' }
  }

  if (payload.type !== 'refresh') {
    throw { statusCode: 401, message: 'Token inválido' }
  }

  const user = await prisma.user.findUnique({
    where: { id: payload.id },
    select: { id: true, email: true, role: true, isActive: true },
  })

  if (!user || !user.isActive) {
    throw { statusCode: 401, message: 'Utilizador não encontrado ou inativo' }
  }

  const accessToken = app.jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    { expiresIn: env.JWT_EXPIRES_IN }
  )

  return { accessToken }
}
