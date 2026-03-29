"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.changePasswordSchema = exports.updateRoleSchema = exports.updateUserSchema = exports.createUserSchema = void 0;
const zod_1 = require("zod");
const client_1 = require("@prisma/client");
exports.createUserSchema = zod_1.z.object({
    name: zod_1.z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
    email: zod_1.z.string().email('Email inválido'),
    password: zod_1.z.string().min(8, 'Password deve ter pelo menos 8 caracteres'),
    role: zod_1.z.nativeEnum(client_1.UserRole).default(client_1.UserRole.OPERATOR),
});
exports.updateUserSchema = zod_1.z.object({
    name: zod_1.z.string().min(2).optional(),
    email: zod_1.z.string().email().optional(),
});
exports.updateRoleSchema = zod_1.z.object({
    role: zod_1.z.nativeEnum(client_1.UserRole, { errorMap: () => ({ message: 'Perfil inválido' }) }),
});
exports.changePasswordSchema = zod_1.z.object({
    currentPassword: zod_1.z.string().min(1, 'Password atual é obrigatória'),
    newPassword: zod_1.z.string().min(8, 'Nova password deve ter pelo menos 8 caracteres'),
});
//# sourceMappingURL=users.schema.js.map