import { FastifyInstance } from 'fastify'
import { authenticate } from '../../middleware/auth'
import { requireAdmin, requireManager } from '../../middleware/permissions'
import {
  createUserSchema,
  updateUserSchema,
  updateRoleSchema,
  changePasswordSchema,
} from './users.schema'
import {
  listUsers,
  getUserById,
  createUser,
  updateUser,
  updateUserRole,
  deactivateUser,
  changePassword,
} from './users.service'

export async function usersRoutes(app: FastifyInstance) {
  app.addHook('preHandler', authenticate)

  // GET /api/users — só ADMIN
  app.get('/', { preHandler: [requireAdmin] }, async (_request, reply) => {
    try {
      return reply.send(await listUsers())
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // GET /api/users/:id — só ADMIN
  app.get('/:id', { preHandler: [requireAdmin] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      return reply.send(await getUserById(id))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // POST /api/users — criar utilizador, MANAGER+
  app.post('/', { preHandler: [requireManager] }, async (request, reply) => {
    const result = createUserSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.status(201).send(await createUser(result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // PUT /api/users/:id — editar utilizador, só ADMIN
  app.put('/:id', { preHandler: [requireAdmin] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const result = updateUserSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await updateUser(id, result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // PATCH /api/users/:id/role — alterar perfil, só ADMIN
  app.patch('/:id/role', { preHandler: [requireAdmin] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const result = updateRoleSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await updateUserRole(id, result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // DELETE /api/users/:id — desativar utilizador, só ADMIN
  app.delete('/:id', { preHandler: [requireAdmin] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const user = request.user as { id: string }
    try {
      return reply.send(await deactivateUser(id, user.id))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // PATCH /api/users/me/password — qualquer utilizador pode mudar a sua própria password
  app.patch('/me/password', async (request, reply) => {
    const user = request.user as { id: string }
    const result = changePasswordSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await changePassword(user.id, result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })
}
