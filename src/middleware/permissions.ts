import { FastifyRequest, FastifyReply } from 'fastify'
import { UserRole } from '../types/enums'

// Hierarquia de permissões (do mais restrito ao mais permissivo)
const ROLE_HIERARCHY: Record<UserRole, number> = {
  VIEWER: 1,
  OPERATOR: 2,
  MANAGER: 3,
  ADMIN: 4,
}

// Cria um middleware que verifica se o utilizador tem o role mínimo necessário
export function requireRole(minimumRole: UserRole) {
  return async (request: FastifyRequest, reply: FastifyReply) => {
    const user = request.user as { id: string; role: UserRole }

    if (!user || !user.role) {
      return reply.status(401).send({
        error: 'Não autorizado',
        message: 'Utilizador não autenticado.',
      })
    }

    const userLevel = ROLE_HIERARCHY[user.role]
    const requiredLevel = ROLE_HIERARCHY[minimumRole]

    if (userLevel < requiredLevel) {
      return reply.status(403).send({
        error: 'Acesso negado',
        message: `Esta ação requer o perfil ${minimumRole} ou superior.`,
      })
    }
  }
}

// Helpers prontos a usar nas rotas
export const requireOperator = requireRole(UserRole.OPERATOR)
export const requireManager = requireRole(UserRole.MANAGER)
export const requireAdmin = requireRole(UserRole.ADMIN)
