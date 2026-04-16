"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.statsRoutes = statsRoutes;
const auth_1 = require("../../middleware/auth");
const permissions_1 = require("../../middleware/permissions");
const stats_service_1 = require("./stats.service");
async function statsRoutes(app) {
    app.addHook('preHandler', auth_1.authenticate);
    // GET /api/stats (ADMIN only)
    app.get('/', { preHandler: [permissions_1.requireAdmin] }, async (request, reply) => {
        try {
            return reply.send(await (0, stats_service_1.getStats)());
        }
        catch (err) {
            return reply.status(500).send({ error: err.message });
        }
    });
}
//# sourceMappingURL=stats.routes.js.map