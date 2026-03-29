import { FastifyInstance } from 'fastify'
import { authenticate } from '../../middleware/auth'
import { requireOperator, requireManager } from '../../middleware/permissions'
import {
  createOrderSchema,
  updateOrderSchema,
  updateStatusSchema,
  listOrdersQuerySchema,
} from './orders.schema'
import {
  listOrders,
  getOrderById,
  createOrder,
  updateOrder,
  updateOrderStatus,
  getOrderHistory,
  cancelOrder,
} from './orders.service'

export async function ordersRoutes(app: FastifyInstance) {
  // Todas as rotas de encomendas requerem autenticação
  app.addHook('preHandler', authenticate)

  // GET /api/orders — listar encomendas com filtros e paginação
  app.get('/', async (request, reply) => {
    const result = listOrdersQuerySchema.safeParse(request.query)
    if (!result.success) {
      return reply.status(400).send({ error: 'Parâmetros inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      const data = await listOrders(result.data)
      return reply.send(data)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // GET /api/orders/:id — detalhe de uma encomenda
  app.get('/:id', async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      const order = await getOrderById(id)
      return reply.send(order)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // POST /api/orders — criar nova encomenda (OPERATOR+)
  app.post('/', { preHandler: [requireOperator] }, async (request, reply) => {
    const result = createOrderSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    const user = request.user as { id: string }
    try {
      const order = await createOrder(result.data, user.id)
      return reply.status(201).send(order)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // PUT /api/orders/:id — editar encomenda (OPERATOR+)
  app.put('/:id', { preHandler: [requireOperator] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const result = updateOrderSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    const user = request.user as { id: string }
    try {
      const order = await updateOrder(id, result.data, user.id)
      return reply.send(order)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // PATCH /api/orders/:id/status — atualizar estado (OPERATOR+)
  app.patch('/:id/status', { preHandler: [requireOperator] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const result = updateStatusSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    const user = request.user as { id: string }
    try {
      const order = await updateOrderStatus(id, result.data, user.id)
      return reply.send(order)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // GET /api/orders/:id/history — histórico de estados
  app.get('/:id/history', async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      const history = await getOrderHistory(id)
      return reply.send(history)
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // DELETE /api/orders/:id — cancelar encomenda (MANAGER+)
  app.delete('/:id', { preHandler: [requireManager] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const user = request.user as { id: string }
    try {
      await cancelOrder(id, user.id)
      return reply.send({ message: 'Encomenda cancelada com sucesso' })
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })
}
