import { FastifyInstance } from 'fastify'
import { authenticate } from '../../middleware/auth'
import { requireOperator } from '../../middleware/permissions'
import {
  createCustomerSchema,
  updateCustomerSchema,
  listCustomersQuerySchema,
} from './customers.schema'
import {
  listCustomers,
  getCustomerById,
  getCustomerOrders,
  createCustomer,
  updateCustomer,
  deleteCustomer,
} from './customers.service'

export async function customersRoutes(app: FastifyInstance) {
  app.addHook('preHandler', authenticate)

  // GET /api/customers
  app.get('/', async (request, reply) => {
    const result = listCustomersQuerySchema.safeParse(request.query)
    if (!result.success) {
      return reply.status(400).send({ error: 'Parâmetros inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await listCustomers(result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // GET /api/customers/:id
  app.get('/:id', async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      return reply.send(await getCustomerById(id))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // GET /api/customers/:id/orders
  app.get('/:id/orders', async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      return reply.send(await getCustomerOrders(id))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // POST /api/customers (OPERATOR+)
  app.post('/', { preHandler: [requireOperator] }, async (request, reply) => {
    const result = createCustomerSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.status(201).send(await createCustomer(result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // PUT /api/customers/:id (OPERATOR+)
  app.put('/:id', { preHandler: [requireOperator] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const result = updateCustomerSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await updateCustomer(id, result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // DELETE /api/customers/:id (OPERATOR+)
  app.delete('/:id', { preHandler: [requireOperator] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      return reply.send(await deleteCustomer(id))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })
}
