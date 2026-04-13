import { FastifyInstance } from 'fastify'
import { authenticate } from '../../middleware/auth'
import { requireOperator } from '../../middleware/permissions'
import { createProductSchema, updateProductSchema, listProductsQuerySchema } from './products.schema'
import {
  listProducts,
  getProductById,
  createProduct,
  updateProduct,
  deleteProduct,
  listCategories,
} from './products.service'

export async function productsRoutes(app: FastifyInstance) {
  app.addHook('preHandler', authenticate)

  // GET /api/products/categories
  app.get('/categories', async (request, reply) => {
    try {
      return reply.send(await listCategories())
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // GET /api/products
  app.get('/', async (request, reply) => {
    const result = listProductsQuerySchema.safeParse(request.query)
    if (!result.success) {
      return reply.status(400).send({ error: 'Parâmetros inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await listProducts(result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // GET /api/products/:id
  app.get('/:id', async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      return reply.send(await getProductById(id))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // POST /api/products (OPERATOR+)
  app.post('/', { preHandler: [requireOperator] }, async (request, reply) => {
    const result = createProductSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.status(201).send(await createProduct(result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // PUT /api/products/:id (OPERATOR+)
  app.put('/:id', { preHandler: [requireOperator] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    const result = updateProductSchema.safeParse(request.body)
    if (!result.success) {
      return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors })
    }
    try {
      return reply.send(await updateProduct(id, result.data))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })

  // DELETE /api/products/:id (OPERATOR+)
  app.delete('/:id', { preHandler: [requireOperator] }, async (request, reply) => {
    const { id } = request.params as { id: string }
    try {
      return reply.send(await deleteProduct(id))
    } catch (err: any) {
      return reply.status(err.statusCode || 500).send({ error: err.message })
    }
  })
}
