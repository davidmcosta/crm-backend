"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.customersRoutes = customersRoutes;
const auth_1 = require("../../middleware/auth");
const permissions_1 = require("../../middleware/permissions");
const customers_schema_1 = require("./customers.schema");
const customers_service_1 = require("./customers.service");
async function customersRoutes(app) {
    app.addHook('preHandler', auth_1.authenticate);
    // GET /api/customers
    app.get('/', async (request, reply) => {
        const result = customers_schema_1.listCustomersQuerySchema.safeParse(request.query);
        if (!result.success) {
            return reply.status(400).send({ error: 'Parâmetros inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, customers_service_1.listCustomers)(result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // GET /api/customers/:id
    app.get('/:id', async (request, reply) => {
        const { id } = request.params;
        try {
            return reply.send(await (0, customers_service_1.getCustomerById)(id));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // GET /api/customers/:id/orders
    app.get('/:id/orders', async (request, reply) => {
        const { id } = request.params;
        try {
            return reply.send(await (0, customers_service_1.getCustomerOrders)(id));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // POST /api/customers (OPERATOR+)
    app.post('/', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const result = customers_schema_1.createCustomerSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.status(201).send(await (0, customers_service_1.createCustomer)(result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // PUT /api/customers/:id (OPERATOR+)
    app.put('/:id', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const { id } = request.params;
        const result = customers_schema_1.updateCustomerSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, customers_service_1.updateCustomer)(id, result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // DELETE /api/customers/:id (OPERATOR+)
    app.delete('/:id', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const { id } = request.params;
        try {
            return reply.send(await (0, customers_service_1.deleteCustomer)(id));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
}
//# sourceMappingURL=customers.routes.js.map