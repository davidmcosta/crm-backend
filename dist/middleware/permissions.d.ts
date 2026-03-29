import { FastifyRequest, FastifyReply } from 'fastify';
import { UserRole } from '@prisma/client';
export declare function requireRole(minimumRole: UserRole): (request: FastifyRequest, reply: FastifyReply) => Promise<undefined>;
export declare const requireOperator: (request: FastifyRequest, reply: FastifyReply) => Promise<undefined>;
export declare const requireManager: (request: FastifyRequest, reply: FastifyReply) => Promise<undefined>;
export declare const requireAdmin: (request: FastifyRequest, reply: FastifyReply) => Promise<undefined>;
//# sourceMappingURL=permissions.d.ts.map