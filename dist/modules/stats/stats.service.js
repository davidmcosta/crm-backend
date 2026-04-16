"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getStats = getStats;
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
// ── Helpers ───────────────────────────────────────────────────────────────────
function toNum(v) {
    if (v == null)
        return 0;
    return typeof v === 'object' && 'toNumber' in v ? v.toNumber() : Number(v);
}
function monthKey(date) {
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`;
}
function monthLabel(date) {
    return date.toLocaleDateString('pt-PT', { month: 'short', year: '2-digit' });
}
// ── Main stats ────────────────────────────────────────────────────────────────
async function getStats() {
    const now = new Date();
    const yearStart = new Date(now.getFullYear(), 0, 1);
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const allOrders = await prisma.order.findMany({
        include: { customer: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'asc' },
    });
    // ── Summary ────────────────────────────────────────────────────────────────
    const ordersThisYear = allOrders.filter(o => o.createdAt >= yearStart);
    const ordersThisMonth = allOrders.filter(o => o.createdAt >= monthStart);
    const revenueThisYear = ordersThisYear
        .filter(o => o.status === 'PAID')
        .reduce((s, o) => s + toNum(o.valorTotal), 0);
    const revenueThisMonth = ordersThisMonth
        .filter(o => o.status === 'PAID')
        .reduce((s, o) => s + toNum(o.valorTotal), 0);
    const allRevenue = allOrders
        .filter(o => o.status === 'PAID')
        .reduce((s, o) => s + toNum(o.valorTotal), 0);
    const paidCount = allOrders.filter(o => o.status === 'PAID').length;
    const pendingCount = allOrders.filter(o => o.status === 'PENDING').length;
    const cancelledCount = allOrders.filter(o => o.status === 'CANCELLED').length;
    const avgOrderValue = paidCount > 0
        ? allOrders.filter(o => o.status === 'PAID').reduce((s, o) => s + toNum(o.valorTotal), 0) / paidCount
        : 0;
    // ── Orders & revenue by month (last 13 months) ─────────────────────────────
    const months = [];
    for (let i = 12; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        months.push({ key: monthKey(d), label: monthLabel(d), date: d });
    }
    const ordersByMonth = months.map(({ key, label, date }) => {
        const nextMonth = new Date(date.getFullYear(), date.getMonth() + 1, 1);
        const mo = allOrders.filter(o => o.createdAt >= date && o.createdAt < nextMonth);
        return {
            key,
            label,
            count: mo.length,
            revenue: mo.filter(o => o.status === 'PAID').reduce((s, o) => s + toNum(o.valorTotal), 0),
        };
    });
    // ── Orders by status ───────────────────────────────────────────────────────
    const statusCounts = {};
    for (const o of allOrders) {
        statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
    }
    // ── Top customers (by order count, top 6) ─────────────────────────────────
    const customerMap = {};
    for (const o of allOrders) {
        if (!o.customerId || !o.customer)
            continue;
        const id = o.customerId;
        if (!customerMap[id])
            customerMap[id] = { name: o.customer.name, count: 0, revenue: 0 };
        customerMap[id].count++;
        if (o.status === 'PAID')
            customerMap[id].revenue += toNum(o.valorTotal);
    }
    const topCustomers = Object.values(customerMap)
        .sort((a, b) => b.count - a.count)
        .slice(0, 6);
    // ── Top products (by quantity sold, top 6) ─────────────────────────────────
    const productMap = {};
    for (const o of allOrders) {
        const prods = o.produtos ?? [];
        for (const p of prods) {
            const name = p.nome || p.name || p.descricao || 'Desconhecido';
            const qty = Number(p.quantidade ?? p.qty ?? 1);
            const val = Number(p.precoUnit ?? p.preco ?? p.price ?? 0) * qty;
            if (!productMap[name])
                productMap[name] = { name, qty: 0, revenue: 0 };
            productMap[name].qty += qty;
            if (o.status === 'PAID')
                productMap[name].revenue += val;
        }
    }
    const topProducts = Object.values(productMap)
        .sort((a, b) => b.qty - a.qty)
        .slice(0, 6);
    // ── Orders by work type (trabalho) ─────────────────────────────────────────
    const workMap = {};
    for (const o of allOrders) {
        const t = o.trabalho?.trim() || 'Outro';
        workMap[t] = (workMap[t] ?? 0) + 1;
    }
    const ordersByWork = Object.entries(workMap)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 8)
        .map(([name, count]) => ({ name, count }));
    return {
        summary: {
            totalOrders: allOrders.length,
            ordersThisYear: ordersThisYear.length,
            ordersThisMonth: ordersThisMonth.length,
            revenueThisYear: Math.round(revenueThisYear * 100) / 100,
            revenueThisMonth: Math.round(revenueThisMonth * 100) / 100,
            totalRevenue: Math.round(allRevenue * 100) / 100,
            avgOrderValue: Math.round(avgOrderValue * 100) / 100,
            paidCount,
            pendingCount,
            cancelledCount,
        },
        ordersByMonth,
        ordersByStatus: statusCounts,
        topCustomers,
        topProducts,
        ordersByWork,
    };
}
//# sourceMappingURL=stats.service.js.map