import { FastifyInstance } from 'fastify'
import { authenticate } from '../../middleware/auth'
import { getSettings } from '../settings/settings.service'
import { calcularViaVerde, debugViaVerde } from './viaverde.service'

export async function viaverdeRoutes(app: FastifyInstance) {

  /**
   * GET /api/viaverde/debug  (sem autenticação — só para diagnóstico)
   * Devolve os inputs/botões encontrados na página da Via Verde.
   */
  app.get('/debug', async (_request, reply) => {
    try {
      const info = await debugViaVerde()
      return reply.send(info)
    } catch (err: any) {
      return reply.status(500).send({ error: err.message })
    }
  })

  app.post('/calcular', { preHandler: authenticate }, async (request, reply) => {
    const { moradaDestino, moradaOrigem: bodyOrigem } = request.body as {
      moradaDestino?: string
      moradaOrigem?:  string
    }

    if (!moradaDestino?.trim()) {
      return reply.status(400).send({ error: 'moradaDestino é obrigatório' })
    }

    try {
      // Origem: prioriza o body; fallback para Settings
      let origem = bodyOrigem?.trim() ?? ''
      if (!origem) {
        const settings = await getSettings()
        origem = (settings as any).moradaOrigem ?? ''
      }

      const result = await calcularViaVerde(origem, moradaDestino.trim())
      return reply.send(result)
    } catch (err: any) {
      return reply
        .status(err.statusCode || 500)
        .send({ error: err.message || 'Erro ao calcular portagens' })
    }
  })
}
