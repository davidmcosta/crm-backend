"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.changePasswordSchema = exports.updateRoleSchema = exports.updateUserSchema = exports.createUserSchema = void 0;
const zod_1 = require("zod");
const enums_1 = require("../../types/enums");
exports.createUserSchema = zod_1.z.object({
    name: zod_1.z.string().min(2, 'Nome deve ter pelo menos 2 caracteres'),
    email: zod_1.z.string().email('Email inválido').optional().nullable(),
    username: zod_1.z.string().min(3, 'Username deve ter pelo menos 3 caracteres').max(30),
    password: zod_1.z.string().min(8, 'Password deve ter pelo menos 8 caracteres'),
    role: zod_1.z.nativeEnum(enums_1.UserRole).default(enums_1.UserRole.OPERATOR),
});
exports.updateUserSchema = zod_1.z.object({
    name: zod_1.z.string().min(2).optional(),
    email: zod_1.z.string().email().optional().nullable(),
    username: zod_1.z.string().min(3).max(30).optional(),
});
exports.updateRoleSchema = zod_1.z.object({
    role: zod_1.z.nativeEnum(enums_1.UserRole, { errorMap: () => ({ message: 'Perfil inválido' }) }),
});
exports.changePasswordSchema = zod_1.z.object({
    currentPassword: zod_1.z.string().min(1, 'Password atual é obrigatória'),
    newPassword: zod_1.z.string().min(8, 'Nova password deve ter pelo menos 8 caracteres'),
});
//# sourceMappingURL=users.schema.js.map