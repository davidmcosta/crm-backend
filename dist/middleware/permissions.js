"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.requireAdmin = exports.requireManager = exports.requireOperator = void 0;
exports.requireRole = requireRole;
const enums_1 = require("../types/enums");
// Hierarquia de permissões (do mais restrito ao mais permissivo)
const ROLE_HIERARCHY = {
    VIEWER: 1,
    OPERATOR: 2,
    MANAGER: 3,
    ADMIN: 4,
};
// Cria um middleware que verifica se o utilizador tem o role mínimo necessário
function requireRole(minimumRole) {
    return async (request, reply) => {
        const user = request.user;
        if (!user || !user.role) {
            return reply.status(401).send({
                error: 'Não autorizado',
                message: 'Utilizador não autenticado.',
            });
        }
        const userLevel = ROLE_HIERARCHY[user.role];
        const requiredLevel = ROLE_HIERARCHY[minimumRole];
        if (userLevel < requiredLevel) {
            return reply.status(403).send({
                error: 'Acesso negado',
                message: `Esta ação requer o perfil ${minimumRole} ou superior.`,
            });
        }
    };
}
// Helpers prontos a usar nas rotas
exports.requireOperator = requireRole(enums_1.UserRole.OPERATOR);
exports.requireManager = requireRole(enums_1.UserRole.MANAGER);
exports.requireAdmin = requireRole(enums_1.UserRole.ADMIN);
//# sourceMappingURL=permissions.js.map