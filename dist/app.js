"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const fastify_1 = __importDefault(require("fastify"));
const jwt_1 = __importDefault(require("@fastify/jwt"));
const cors_1 = __importDefault(require("@fastify/cors"));
const env_1 = require("./config/env");
const auth_routes_1 = require("./modules/auth/auth.routes");
const orders_routes_1 = require("./modules/orders/orders.routes");
const customers_routes_1 = require("./modules/customers/customers.routes");
const users_routes_1 = require("./modules/users/users.routes");
const app = (0, fastify_1.default)({
    logger: env_1.env.NODE_ENV === 'development'
        ? { transport: { target: 'pino-pretty', options: { colorize: true } } }
        : true,
});
// ─────────────────────────────────────────
// Plugins
// ─────────────────────────────────────────
app.register(cors_1.default, {
    origin: true, // Em produção, substitui por: origin: ['https://teu-dominio.com']
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
});
app.register(jwt_1.default, {
    secret: env_1.env.JWT_SECRET,
});
// ─────────────────────────────────────────
// Rotas
// ─────────────────────────────────────────
app.register(auth_routes_1.authRoutes, { prefix: '/api/auth' });
app.register(orders_routes_1.ordersRoutes, { prefix: '/api/orders' });
app.register(customers_routes_1.customersRoutes, { prefix: '/api/customers' });
app.register(users_routes_1.usersRoutes, { prefix: '/api/users' });
// Health check
app.get('/health', async () => ({
    status: 'ok',
    timestamp: new Date().toISOString(),
    environment: env_1.env.NODE_ENV,
}));
// ─────────────────────────────────────────
// Arrancar servidor
// ─────────────────────────────────────────
const start = async () => {
    try {
        await app.listen({ port: env_1.env.PORT, host: '0.0.0.0' });
        console.log(`\n🚀 Servidor a correr em http://localhost:${env_1.env.PORT}`);
        console.log(`📋 Health check: http://localhost:${env_1.env.PORT}/health\n`);
    }
    catch (err) {
        app.log.error(err);
        process.exit(1);
    }
};
start();
//# sourceMappingURL=app.js.map