"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.loginService = loginService;
exports.refreshTokenService = refreshTokenService;
const client_1 = require("@prisma/client");
const hash_1 = require("../../utils/hash");
const env_1 = require("../../config/env");
const prisma = new client_1.PrismaClient();
async function loginService(app, data) {
    const user = await prisma.user.findUnique({
        where: { email: data.email },
        select: {
            id: true,
            name: true,
            email: true,
            password: true,
            role: true,
            isActive: true,
        },
    });
    if (!user || !user.isActive) {
        throw { statusCode: 401, message: 'Credenciais inválidas' };
    }
    const passwordMatch = await (0, hash_1.comparePassword)(data.password, user.password);
    if (!passwordMatch) {
        throw { statusCode: 401, message: 'Credenciais inválidas' };
    }
    const payload = { id: user.id, email: user.email, role: user.role };
    const accessToken = app.jwt.sign(payload, {
        expiresIn: env_1.env.JWT_EXPIRES_IN,
    });
    // Refresh token com secret diferente e validade maior
    const refreshToken = app.jwt.sign({ id: user.id, type: 'refresh' }, { expiresIn: env_1.env.JWT_REFRESH_EXPIRES_IN });
    return {
        accessToken,
        refreshToken,
        user: {
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
        },
    };
}
async function refreshTokenService(app, refreshToken) {
    let payload;
    try {
        payload = app.jwt.verify(refreshToken);
    }
    catch {
        throw { statusCode: 401, message: 'Refresh token inválido ou expirado' };
    }
    if (payload.type !== 'refresh') {
        throw { statusCode: 401, message: 'Token inválido' };
    }
    const user = await prisma.user.findUnique({
        where: { id: payload.id },
        select: { id: true, email: true, role: true, isActive: true },
    });
    if (!user || !user.isActive) {
        throw { statusCode: 401, message: 'Utilizador não encontrado ou inativo' };
    }
    const accessToken = app.jwt.sign({ id: user.id, email: user.email, role: user.role }, { expiresIn: env_1.env.JWT_EXPIRES_IN });
    return { accessToken };
}
//# sourceMappingURL=auth.service.js.map