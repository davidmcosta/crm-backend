"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ordersRoutes = ordersRoutes;
const auth_1 = require("../../middleware/auth");
const permissions_1 = require("../../middleware/permissions");
const orders_schema_1 = require("./orders.schema");
const orders_service_1 = require("./orders.service");
async function ordersRoutes(app) {
    // Todas as rotas de encomendas requerem autenticação
    app.addHook('preHandler', auth_1.authenticate);
    // GET /api/orders — listar encomendas com filtros e paginação
    app.get('/', async (request, reply) => {
        const result = orders_schema_1.listOrdersQuerySchema.safeParse(request.query);
        if (!result.success) {
            return reply.status(400).send({ error: 'Parâmetros inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            const data = await (0, orders_service_1.listOrders)(result.data);
            return reply.send(data);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // GET /api/orders/:id — detalhe de uma encomenda
    app.get('/:id', async (request, reply) => {
        const { id } = request.params;
        try {
            const order = await (0, orders_service_1.getOrderById)(id);
            return reply.send(order);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // POST /api/orders — criar nova encomenda (OPERATOR+)
    app.post('/', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const result = orders_schema_1.createOrderSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        const user = request.user;
        try {
            const order = await (0, orders_service_1.createOrder)(result.data, user.id);
            return reply.status(201).send(order);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // PUT /api/orders/:id — editar encomenda (OPERATOR+)
    app.put('/:id', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const { id } = request.params;
        const result = orders_schema_1.updateOrderSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        const user = request.user;
        try {
            const order = await (0, orders_service_1.updateOrder)(id, result.data, user.id);
            return reply.send(order);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // PATCH /api/orders/:id/status — atualizar estado (OPERATOR+)
    app.patch('/:id/status', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const { id } = request.params;
        const result = orders_schema_1.updateStatusSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        const user = request.user;
        try {
            const order = await (0, orders_service_1.updateOrderStatus)(id, result.data, user.id);
            return reply.send(order);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // GET /api/orders/:id/history — histórico de estados
    app.get('/:id/history', async (request, reply) => {
        const { id } = request.params;
        try {
            const history = await (0, orders_service_1.getOrderHistory)(id);
            return reply.send(history);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // DELETE /api/orders/:id — eliminar encomenda (MANAGER+)
    app.delete('/:id', { preHandler: [permissions_1.requireManager] }, async (request, reply) => {
        const { id } = request.params;
        try {
            const result = await (0, orders_service_1.deleteOrder)(id);
            return reply.send(result);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
}
//# sourceMappingURL=orders.routes.js.map