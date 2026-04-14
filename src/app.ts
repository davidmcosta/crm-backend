import 'dotenv/config'
import Fastify from 'fastify'
import fastifyJwt from '@fastify/jwt'
import fastifyCors from '@fastify/cors'
import { env } from './config/env'
import { authRoutes } from './modules/auth/auth.routes'
import { ordersRoutes } from './modules/orders/orders.routes'
import { customersRoutes } from './modules/customers/customers.routes'
import { usersRoutes } from './modules/users/users.routes'
import { productsRoutes } from './modules/products/products.routes'
import { settingsRoutes } from './modules/settings/settings.routes'

const app = Fastify({
  logger: env.NODE_ENV === 'development'
    ? { transport: { target: 'pino-pretty', options: { colorize: true } } }
    : true,
})

// ─────────────────────────────────────────
// Content-type parser — aceita body vazio
// (o Dio envia Content-Type: application/json mesmo em DELETE sem body)
// ─────────────────────────────────────────

app.addContentTypeParser(
  'application/json',
  { parseAs: 'string' },
  (_req, body, done) => {
    const str = body as string
    if (!str || str.length === 0) {
      done(null, null)
      return
    }
    try {
      done(null, JSON.parse(str))
    } catch (err: any) {
      err.statusCode = 400
      done(err, undefined)
    }
  },
)

// ─────────────────────────────────────────
// Plugins
// ─────────────────────────────────────────

app.register(fastifyCors, {
  origin: true, // Em produção, substitui por: origin: ['https://teu-dominio.com']
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
})

app.register(fastifyJwt, {
  secret: env.JWT_SECRET,
})

// ─────────────────────────────────────────
// Rotas
// ─────────────────────────────────────────

app.register(authRoutes, { prefix: '/api/auth' })
app.register(ordersRoutes, { prefix: '/api/orders' })
app.register(customersRoutes, { prefix: '/api/customers' })
app.register(usersRoutes, { prefix: '/api/users' })
app.register(productsRoutes, { prefix: '/api/products' })
app.register(settingsRoutes, { prefix: '/api/settings' })

// Health check
app.get('/health', async () => ({
  status: 'ok',
  timestamp: new Date().toISOString(),
  environment: env.NODE_ENV,
}))

// ─────────────────────────────────────────
// Arrancar servidor
// ─────────────────────────────────────────

const start = async () => {
  try {
    await app.listen({ port: env.PORT, host: '0.0.0.0' })
    console.log(`\n🚀 Servidor a correr em http://localhost:${env.PORT}`)
    console.log(`📋 Health check: http://localhost:${env.PORT}/health\n`)
  } catch (err) {
    app.log.error(err)
    process.exit(1)
  }
}

start()
