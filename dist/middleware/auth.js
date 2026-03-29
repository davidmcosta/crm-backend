"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authenticate = authenticate;
// Garante que o utilizador está autenticado
async function authenticate(request, reply) {
    try {
        await request.jwtVerify();
    }
    catch (err) {
        return reply.status(401).send({
            error: 'Não autorizado',
            message: 'Token inválido ou expirado. Faz login novamente.',
        });
    }
}
//# sourceMappingURL=auth.js.map