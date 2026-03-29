import { FastifyInstance } from 'fastify'
import { loginSchema, refreshSchema } from './auth.schema'
import { loginService, refreshTokenService } from './auth.service'
import { authenticate } from '../../middleware/auth'

export async function authRoutes(app: FastifyInstance) {
  // POST /api/auth/login
  app.post('/login', async (request, reply) => {
    const result = loginSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({
        error: 'Dados inválidos',
        details: result.error.flatten().fieldErrors,
      })
    }

    try {
      const data = await loginService(app, result.data)
      return reply.status(200).send(data)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // POST /api/auth/refresh
  app.post('/refresh', async (request, reply) => {
    const result = refreshSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({
        error: 'Dados inválidos',
        details: result.error.flatten().fieldErrors,
      })
    }

    try {
      const data = await refreshTokenService(app, result.data.refreshToken)
      return reply.status(200).send(data)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // POST /api/auth/logout (stateless — o cliente apaga os tokens localmente)
  app.post('/logout', { preHandler: [authenticate] }, async (_request, reply) => {
    return reply.status(200).send({ message: 'Logout efetuado com sucesso' })
  })

  // GET /api/auth/me — devolve o utilizador autenticado atual
  app.get('/me', { preHandler: [authenticate] }, async (request, reply) => {
    const user = request.user as { id: string; email: string; role: string }
    return reply.status(200).send({ user })
  })
}
