"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authRoutes = authRoutes;
const auth_schema_1 = require("./auth.schema");
const auth_service_1 = require("./auth.service");
const auth_1 = require("../../middleware/auth");
async function authRoutes(app) {
    // POST /api/auth/login
    app.post('/login', async (request, reply) => {
        const result = auth_schema_1.loginSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({
                error: 'Dados inválidos',
                details: result.error.flatten().fieldErrors,
            });
        }
        try {
            const data = await (0, auth_service_1.loginService)(app, result.data);
            return reply.status(200).send(data);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // POST /api/auth/refresh
    app.post('/refresh', async (request, reply) => {
        const result = auth_schema_1.refreshSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({
                error: 'Dados inválidos',
                details: result.error.flatten().fieldErrors,
            });
        }
        try {
            const data = await (0, auth_service_1.refreshTokenService)(app, result.data.refreshToken);
            return reply.status(200).send(data);
        }
        catch (err) {
            return reply.status(err.statusCode || 500).send({ error: err.message });
        }
    });
    // POST /api/auth/logout (stateless — o cliente apaga os tokens localmente)
    app.post('/logout', { preHandler: [auth_1.authenticate] }, async (_request, reply) => {
        return reply.status(200).send({ message: 'Logout efetuado com sucesso' });
    });
    // GET /api/auth/me — devolve o utilizador autenticado atual
    app.get('/me', { preHandler: [auth_1.authenticate] }, async (request, reply) => {
        const user = request.user;
        return reply.status(200).send({ user });
    });
}
//# sourceMappingURL=auth.routes.js.map