import { FastifyInstance } from 'fastify'
import { authenticate } from '../../middleware/auth'
import { requireAdmin } from '../../middleware/permissions'
import { getStats } from './stats.service'

export async function statsRoutes(app: FastifyInstance) {
  app.addHook('preHandler', authenticate)

  // GET /api/stats (ADMIN only)
  app.get('/', { preHandler: [requireAdmin] }, async (request, reply) => {
    try {
      return reply.send(await getStats())
    } catch (err: any) {
      return reply.status(500).send({ error: err.message })
    }
  })
}
