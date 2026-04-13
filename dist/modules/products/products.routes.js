"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.productsRoutes = productsRoutes;
const auth_1 = require("../../middleware/auth");
const permissions_1 = require("../../middleware/permissions");
const products_schema_1 = require("./products.schema");
const products_service_1 = require("./products.service");
async function productsRoutes(app) {
    app.addHook('preHandler', auth_1.authenticate);
    // GET /api/products/categories
    app.get('/categories', async (request, reply) => {
        try {
            return reply.send(await (0, products_service_1.listCategories)());
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // GET /api/products
    app.get('/', async (request, reply) => {
        const result = products_schema_1.listProductsQuerySchema.safeParse(request.query);
        if (!result.success) {
            return reply.status(400).send({ error: 'Parâmetros inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, products_service_1.listProducts)(result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // GET /api/products/:id
    app.get('/:id', async (request, reply) => {
        const { id } = request.params;
        try {
            return reply.send(await (0, products_service_1.getProductById)(id));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // POST /api/products (OPERATOR+)
    app.post('/', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const result = products_schema_1.createProductSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.status(201).send(await (0, products_service_1.createProduct)(result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // PUT /api/products/:id (OPERATOR+)
    app.put('/:id', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const { id } = request.params;
        const result = products_schema_1.updateProductSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, products_service_1.updateProduct)(id, result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // DELETE /api/products/:id (OPERATOR+)
    app.delete('/:id', { preHandler: [permissions_1.requireOperator] }, async (request, reply) => {
        const { id } = request.params;
        try {
            return reply.send(await (0, products_service_1.deleteProduct)(id));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
}
//# sourceMappingURL=products.routes.js.map