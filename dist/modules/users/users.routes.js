"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.usersRoutes = usersRoutes;
const auth_1 = require("../../middleware/auth");
const permissions_1 = require("../../middleware/permissions");
const users_schema_1 = require("./users.schema");
const users_service_1 = require("./users.service");
async function usersRoutes(app) {
    app.addHook('preHandler', auth_1.authenticate);
    // GET /api/users — só ADMIN
    app.get('/', { preHandler: [permissions_1.requireAdmin] }, async (_request, reply) => {
        try {
            return reply.send(await (0, users_service_1.listUsers)());
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // GET /api/users/:id — só ADMIN
    app.get('/:id', { preHandler: [permissions_1.requireAdmin] }, async (request, reply) => {
        const { id } = request.params;
        try {
            return reply.send(await (0, users_service_1.getUserById)(id));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // POST /api/users — criar utilizador, só ADMIN
    app.post('/', { preHandler: [permissions_1.requireAdmin] }, async (request, reply) => {
        const result = users_schema_1.createUserSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.status(201).send(await (0, users_service_1.createUser)(result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // PUT /api/users/:id — editar utilizador, só ADMIN
    app.put('/:id', { preHandler: [permissions_1.requireAdmin] }, async (request, reply) => {
        const { id } = request.params;
        const result = users_schema_1.updateUserSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, users_service_1.updateUser)(id, result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // PATCH /api/users/:id/role — alterar perfil, só ADMIN
    app.patch('/:id/role', { preHandler: [permissions_1.requireAdmin] }, async (request, reply) => {
        const { id } = request.params;
        const result = users_schema_1.updateRoleSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, users_service_1.updateUserRole)(id, result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // DELETE /api/users/:id — desativar utilizador, só ADMIN
    app.delete('/:id', { preHandler: [permissions_1.requireAdmin] }, async (request, reply) => {
        const { id } = request.params;
        const user = request.user;
        try {
            return reply.send(await (0, users_service_1.deactivateUser)(id, user.id));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // PATCH /api/users/me/password — qualquer utilizador pode mudar a sua própria password
    app.patch('/me/password', async (request, reply) => {
        const user = request.user;
        const result = users_schema_1.changePasswordSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, users_service_1.changePassword)(user.id, result.data));
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
}
//# sourceMappingURL=users.routes.js.map