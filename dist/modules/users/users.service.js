"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listUsers = listUsers;
exports.getUserById = getUserById;
exports.createUser = createUser;
exports.updateUser = updateUser;
exports.updateUserRole = updateUserRole;
exports.deactivateUser = deactivateUser;
exports.changePassword = changePassword;
const client_1 = require("@prisma/client");
const hash_1 = require("../../utils/hash");
const prisma = new client_1.PrismaClient();
async function listUsers() {
    return prisma.user.findMany({
        where: { isActive: true },
        select: {
            id: true,
            name: true,
            email: true,
            username: true,
            role: true,
            isActive: true,
            createdAt: true,
        },
        orderBy: { name: 'asc' },
    });
}
async function getUserById(id) {
    const user = await prisma.user.findUnique({
        where: { id },
        select: {
            id: true,
            name: true,
            email: true,
            username: true,
            role: true,
            isActive: true,
            createdAt: true,
            _count: { select: { orders: true } },
        },
    });
    if (!user)
        throw { statusCode: 404, message: 'Utilizador não encontrado' };
    return user;
}
async function createUser(data) {
    const existing = await prisma.user.findFirst({
        where: {
            OR: [
                { email: data.email },
                { username: data.username || undefined },
            ],
        },
    });
    if (existing)
        throw { statusCode: 409, message: 'Já existe um utilizador com este email ou utilizador' };
    const hashedPassword = await (0, hash_1.hashPassword)(data.password);
    return prisma.user.create({
        data: { ...data, password: hashedPassword },
        select: { id: true, name: true, email: true, username: true, role: true, isActive: true, createdAt: true },
    });
}
async function updateUser(id, data) {
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user)
        throw { statusCode: 404, message: 'Utilizador não encontrado' };
    if (data.email && data.email !== user.email) {
        const existing = await prisma.user.findUnique({ where: { email: data.email } });
        if (existing)
            throw { statusCode: 409, message: 'Já existe um utilizador com este email' };
    }
    if (data.username && data.username !== user.username) {
        const existing = await prisma.user.findUnique({ where: { username: data.username } });
        if (existing)
            throw { statusCode: 409, message: 'Já existe um utilizador com este nome de utilizador' };
    }
    return prisma.user.update({
        where: { id },
        data,
        select: { id: true, name: true, email: true, username: true, role: true, isActive: true },
    });
}
async function updateUserRole(id, data) {
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user)
        throw { statusCode: 404, message: 'Utilizador não encontrado' };
    return prisma.user.update({
        where: { id },
        data: { role: data.role },
        select: { id: true, name: true, email: true, role: true },
    });
}
async function deactivateUser(id, requestingUserId) {
    if (id === requestingUserId) {
        throw { statusCode: 400, message: 'Não podes desativar a tua própria conta' };
    }
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user)
        throw { statusCode: 404, message: 'Utilizador não encontrado' };
    return prisma.user.update({
        where: { id },
        data: { isActive: false },
        select: { id: true, name: true, isActive: true },
    });
}
async function changePassword(id, data) {
    const user = await prisma.user.findUnique({ where: { id } });
    if (!user)
        throw { statusCode: 404, message: 'Utilizador não encontrado' };
    const match = await (0, hash_1.comparePassword)(data.currentPassword, user.password);
    if (!match)
        throw { statusCode: 401, message: 'Password atual incorreta' };
    const newHash = await (0, hash_1.hashPassword)(data.newPassword);
    await prisma.user.update({ where: { id }, data: { password: newHash } });
    return { message: 'Password alterada com sucesso' };
}
//# sourceMappingURL=users.service.js.map