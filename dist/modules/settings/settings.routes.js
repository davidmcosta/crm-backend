"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.settingsRoutes = settingsRoutes;
const auth_1 = require("../../middleware/auth");
const permissions_1 = require("../../middleware/permissions");
const settings_service_1 = require("./settings.service");
const zod_1 = require("zod");
const updateSettingsSchema = zod_1.z.object({
    anoAtual: zod_1.z.number().int().min(0).optional(),
    kmRate: zod_1.z.number().min(0).optional(),
    mealCost: zod_1.z.number().min(0).optional(),
    anosVisiveis: zod_1.z.array(zod_1.z.number().int()).optional(),
});
async function settingsRoutes(app) {
    app.addHook('preHandler', auth_1.authenticate);
    // GET /api/settings
    app.get('/', async (request, reply) => {
        try {
            return reply.send(await (0, settings_service_1.getSettings)());
        }
        catch (err) {
            return reply.status(500).send({ error: err.message });
        }
    });
    // PUT /api/settings (MANAGER+)
    app.put('/', { preHandler: [permissions_1.requireManager] }, async (request, reply) => {
        const result = updateSettingsSchema.safeParse(request.body);
        if (!result.success) {
            return reply.status(400).send({ error: 'Dados inválidos', details: result.error.flatten().fieldErrors });
        }
        try {
            return reply.send(await (0, settings_service_1.updateSettings)(result.data));
        }
        catch (err) {
            return reply.status(500).send({ error: err.message });
        }
    });
}
//# sourceMappingURL=settings.routes.js.map