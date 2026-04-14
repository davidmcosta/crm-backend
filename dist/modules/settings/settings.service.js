"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSettings = getSettings;
exports.updateSettings = updateSettings;
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function getSettings() {
    let settings = await prisma.settings.findUnique({ where: { id: 'global' } });
    if (!settings) {
        settings = await prisma.settings.create({
            data: { id: 'global', anoAtual: 0, kmRate: 0.36, mealCost: 12 },
        });
    }
    return settings;
}
async function updateSettings(data) {
    return prisma.settings.upsert({
        where: { id: 'global' },
        create: { id: 'global', anoAtual: 0, kmRate: 0.36, mealCost: 12, anosVisiveis: [], ...data },
        update: { ...data, updatedAt: new Date() },
    });
}
//# sourceMappingURL=settings.service.js.map