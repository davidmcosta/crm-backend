import { PrismaClient, OrderStatus } from '@prisma/client'
import { CreateOrderInput, UpdateOrderInput, UpdateStatusInput, ListOrdersQuery } from './orders.schema'

const prisma = new PrismaClient()

// ── Gerar número de encomenda no formato 01/26, 02/26, ... ──────────────────
async function generateOrderNumber(): Promise<string> {
  const now = new Date()
  const year = String(now.getFullYear()).slice(-2)   // "26"

  const lastOrder = await prisma.order.findFirst({
    where: { orderNumber: { endsWith: `/${year}` } },
    orderBy: { createdAt: 'desc' },
    select: { orderNumber: true },
  })

  let nextNum = 1
  if (lastOrder) {
    const seq = lastOrder.orderNumber.split('/')[0]
    nextNum = parseInt(seq, 10) + 1
  }

  return `${String(nextNum).padStart(2, '0')}/${year}`
}

// ── Listagem ─────────────────────────────────────────────────────────────────
export async function listOrders(query: ListOrdersQuery) {
  const { page, limit, status, customerId, search } = query
  const skip = (page - 1) * limit
  const where: any = {}
  if (status) where.status = status
  if (customerId) where.customerId = customerId
  if (search) {
    where.OR = [
      { orderNumber: { contains: search, mode: 'insensitive' } },
      { nomeFalecido: { contains: search, mode: 'insensitive' } },
      { requerente: { contains: search, mode: 'insensitive' } },
      { cemiterio: { contains: search, mode: 'insensitive' } },
      { customer: { name: { contains: search, mode: 'insensitive' } } },
    ]
  }

  const [orders, total] = await Promise.all([
    prisma.order.findMany({
      where, skip, take: limit, orderBy: { createdAt: 'desc' },
      include: {
        customer: { select: { id: true, name: true, email: true } },
        createdBy: { select: { id: true, name: true } },
      },
    }),
    prisma.order.count({ where }),
  ])

  return {
    data: orders,
    pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
  }
}

// ── Detalhe ──────────────────────────────────────────────────────────────────
export async function getOrderById(id: string) {
  const order = await prisma.order.findUnique({
    where: { id },
    include: {
      customer: true,
      createdBy: { select: { id: true, name: true, email: true } },
      statusHistory: {
        include: { changedBy: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
      },
    },
  })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  return order
}

// ── Criar encomenda ──────────────────────────────────────────────────────────
export async function createOrder(data: CreateOrderInput, userId: string) {
  if (data.customerId) {
    const customer = await prisma.customer.findUnique({ where: { id: data.customerId } })
    if (!customer) throw { statusCode: 404, message: 'Cliente não encontrado' }
  }

  const orderNumber = await generateOrderNumber()

  return prisma.order.create({
    data: {
      orderNumber,
      status: OrderStatus.PENDING,
      createdById: userId,
      customerId: data.customerId ?? null,

      trabalho: data.trabalho,
      cemiterio: data.cemiterio ?? null,
      talhao: data.talhao ?? null,
      numeroSepultura: data.numeroSepultura ?? null,

      fotoPessoa: data.fotoPessoa ?? null,
      nomeFalecido: data.nomeFalecido,
      datasFalecido: data.datasFalecido ?? null,

      valorSepultura: data.valorSepultura ?? 0,
      km: data.km ?? null,
      portagens: data.portagens ?? 0,
      deslocacaoMontagem: data.deslocacaoMontagem ?? 0,
      extrasDescricao: data.extrasDescricao ?? null,
      extrasValor: data.extrasValor ?? 0,
      valorTotal: data.valorTotal ?? 0,

      requerente: data.requerente,
      contacto: data.contacto,
      observacoes: data.observacoes ?? null,

      statusHistory: {
        create: { status: OrderStatus.PENDING, changedById: userId, notes: 'Encomenda criada' },
      },
    },
    include: {
      customer: { select: { id: true, name: true } },
    },
  })
}

// ── Atualizar encomenda ──────────────────────────────────────────────────────
export async function updateOrder(id: string, data: UpdateOrderInput, userId: string) {
  const existing = await prisma.order.findUnique({ where: { id } })
  if (!existing) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  if (existing.status === OrderStatus.CANCELLED) {
    throw { statusCode: 400, message: 'Não é possível editar uma encomenda cancelada' }
  }

  return prisma.order.update({
    where: { id },
    data: { ...data, updatedAt: new Date() },
    include: { customer: { select: { id: true, name: true } } },
  })
}

// ── Atualizar estado ─────────────────────────────────────────────────────────
export async function updateOrderStatus(id: string, data: UpdateStatusInput, userId: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  if (order.status === OrderStatus.CANCELLED) {
    throw { statusCode: 400, message: 'Não é possível alterar o estado de uma encomenda cancelada' }
  }
  if (order.status === data.status) {
    throw { statusCode: 400, message: 'A encomenda já se encontra neste estado' }
  }

  const [updatedOrder] = await prisma.$transaction([
    prisma.order.update({ where: { id }, data: { status: data.status } }),
    prisma.orderStatusHistory.create({
      data: { orderId: id, status: data.status, changedById: userId, notes: data.notes },
    }),
  ])
  return updatedOrder
}

// ── Histórico de estados ─────────────────────────────────────────────────────
export async function getOrderHistory(id: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  return prisma.orderStatusHistory.findMany({
    where: { orderId: id },
    include: { changedBy: { select: { id: true, name: true } } },
    orderBy: { createdAt: 'desc' },
  })
}

// ── Cancelar encomenda ───────────────────────────────────────────────────────
export async function cancelOrder(id: string, userId: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  if (order.status === OrderStatus.CANCELLED) {
    throw { statusCode: 400, message: 'A encomenda já está cancelada' }
  }

  const [updatedOrder] = await prisma.$transaction([
    prisma.order.update({ where: { id }, data: { status: OrderStatus.CANCELLED } }),
    prisma.orderStatusHistory.create({
      data: { orderId: id, status: OrderStatus.CANCELLED, changedById: userId, notes: 'Encomenda cancelada' },
    }),
  ])
  return updatedOrder
}
