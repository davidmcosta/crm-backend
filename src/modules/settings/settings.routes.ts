import { FastifyInstance } from 'fastify'
import { authenticate } from '../../middleware/auth'
import { requireManager } from '../../middleware/permissions'
import { getSettings, updateSettings } from './settings.service'
import { z } from 'zod'

const updateSettingsSchema = z.object({
  anoAtual:  z.number().int().min(0).optional(),
  kmRate:    z.number().min(0).optional(),
  mealCost:  z.number().min(0).optional(),
  anosVisiveis: z.array(z.number().int()).optional(),
})

export async function settingsRoutes(app: FastifyInstance) {
  app.addHook('preHandler', authenticate)

  // GET /api/settings
  app.get('/', async (request, reply) => {
    try {
      return reply.send(await getSettings())
    } catch (err: any) {
      return reply.status(500).send({ error: err.message })
    }
  })

  // PUT /api/settings (MANAGER+)
  app.put('/', { preHandler: [requireManager] }, async (request, reply) => {
    const result = updateSettingsSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await updateSettings(result.data))
    } catch (err: any) {
      return reply.status(500).send({ error: err.message })
    }
  })
}
