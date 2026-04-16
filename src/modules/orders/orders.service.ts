import { PrismaClient } from '@prisma/client'
import { OrderStatus } from '../../types/enums'
import { CreateOrderInput, UpdateOrderInput, UpdateStatusInput, ListOrdersQuery } from './orders.schema'

const prisma = new PrismaClient()

// ── Número de encomenda 01/26, 02/26, ... ───────────────────────────────────
async function generateOrderNumber(): Promise<string> {
  // Use settings anoAtual if set; otherwise current year
  let yearFull = new Date().getFullYear()
  let numeroInicial = 1
  try {
    const settings = await (prisma as any).settings.findUnique({ where: { id: 'global' } })
    if (settings && settings.anoAtual > 0) yearFull = settings.anoAtual
    if (settings && settings.numeroInicial > 1) numeroInicial = settings.numeroInicial
  } catch {}
  const year = String(yearFull).slice(-2)
  const last = await prisma.order.findFirst({
    where: { orderNumber: { endsWith: `/${year}` } },
    orderBy: { createdAt: 'desc' },
    select: { orderNumber: true },
  })
  // If no orders exist for this year, start at numeroInicial; otherwise increment last
  const next = last ? parseInt(last.orderNumber.split('/')[0], 10) + 1 : numeroInicial
  return `${String(next).padStart(2, '0')}/${year}`
}

// ── Listagem ─────────────────────────────────────────────────────────────────
export async function listOrders(query: ListOrdersQuery) {
  const { page, limit, status, customerId, search, cemiterio, trabalho, produto, dateFrom, dateTo } = query
  const skip  = (page - 1) * limit
  const where: any = {}
  // Collects multiple AND-combined conditions (each may be an OR block)
  const andConditions: any[] = []

  // Load settings — apply year filter based on orderNumber suffix (e.g. "01/25")
  // Only applies when no explicit dateFrom/dateTo filter is active
  if (!dateFrom && !dateTo) {
    try {
      const settings = await (prisma as any).settings.findUnique({ where: { id: 'global' } })
      if (settings && Array.isArray(settings.anosVisiveis) && settings.anosVisiveis.length > 0) {
        const years = settings.anosVisiveis as number[]
        andConditions.push({
          OR: years.map((y: number) => ({
            orderNumber: { endsWith: `/${String(y).slice(-2)}` },
          })),
        })
      }
    } catch {}
  }

  if (status)     where.status     = status
  if (customerId) where.customerId = customerId

  // Filtros de campo específico
  if (cemiterio) where.cemiterio = { contains: cemiterio, mode: 'insensitive' }
  if (trabalho)  where.trabalho  = { contains: trabalho,  mode: 'insensitive' }

  // Filtro por intervalo de datas explícito
  if (dateFrom || dateTo) {
    const dateFilter: Record<string, Date> = {}
    if (dateFrom) dateFilter['gte'] = new Date(dateFrom as string)
    if (dateTo) {
      const end = new Date(dateTo as string)
      end.setHours(23, 59, 59, 999)
      dateFilter['lte'] = end
    }
    where.createdAt = dateFilter
  }

  // Pesquisa de texto geral (ordem, falecido, requerente, cemitério, obs, dedicatória, cliente)
  if (search) {
    andConditions.push({ OR: [
      { orderNumber:  { contains: search, mode: 'insensitive' } },
      { nomeFalecido: { contains: search, mode: 'insensitive' } },
      { requerente:   { contains: search, mode: 'insensitive' } },
      { cemiterio:    { contains: search, mode: 'insensitive' } },
      { observacoes:  { contains: search, mode: 'insensitive' } },
      { dedicatoria:  { contains: search, mode: 'insensitive' } },
      { customer: { name: { contains: search, mode: 'insensitive' } } },
    ]})
  }

  // Pesquisa por nome de produto (dentro do campo trabalho e também texto livre)
  if (produto) {
    andConditions.push({ OR: [
      { trabalho: { contains: produto, mode: 'insensitive' } },
      { nomeFalecido: { contains: produto, mode: 'insensitive' } },
    ]})
  }

  if (andConditions.length > 0) {
    where.AND = andConditions
  }

  const [orders, total] = await Promise.all([
    prisma.order.findMany({
      where, skip, take: limit, orderBy: { createdAt: 'asc' },
      include: {
        customer:  { select: { id: true, name: true, email: true } },
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
      customer:  true,
      createdBy: { select: { id: true, name: true, email: true } },
      statusHistory: {
        include: { changedBy: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
      },
    },
  })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }

  // Verificar se esta é a encomenda mais recente (sem nenhuma criada depois)
  const newerOrder = await prisma.order.findFirst({
    where: { createdAt: { gt: order.createdAt } },
    select: { id: true },
  })
  return { ...order, isLastOrder: newerOrder === null }
}

// ── Criar ────────────────────────────────────────────────────────────────────
export async function createOrder(data: CreateOrderInput, userId: string) {
  if (data.customerId) {
    const customer = await prisma.customer.findUnique({ where: { id: data.customerId } })
    if (!customer) throw { statusCode: 404, message: 'Cliente não encontrado' }
  }

  const orderNumber = await generateOrderNumber()
  const extrasTotal = (data.extras ?? []).reduce((sum, e) => sum + e.valor, 0)

  return prisma.order.create({
    data: {
      orderNumber,
      status:      OrderStatus.PENDING,
      createdById: userId,
      customerId:  data.customerId ?? null,

      trabalho:        data.trabalho,
      cemiterio:       data.cemiterio ?? null,
      talhao:          data.talhao ?? null,
      numeroSepultura: data.numeroSepultura ?? null,

      falecidos:     data.falecidos     ?? [],
      fotosPessoa:   data.fotosPessoa   ?? [],
      fotoPessoa:    (data.fotosPessoa && data.fotosPessoa.length > 0)
                       ? data.fotosPessoa[0]
                       : (data.fotoPessoa ?? null),
      nomeFalecido:  data.nomeFalecido  ?? null,
      datasFalecido: data.datasFalecido ?? null,
      dedicatoria:   data.dedicatoria   ?? null,

      produtos: data.produtos ?? [],
      extras:   data.extras   ?? [],

      valorSepultura:     data.valorSepultura     ?? 0,
      km:                 data.km                 ?? null,
      portagens:          data.portagens          ?? 0,
      refeicoes:          data.refeicoes          ?? 0,
      deslocacaoMontagem: data.deslocacaoMontagem ?? 0,
      extrasValor:        extrasTotal,
      valorTotal:         data.valorTotal         ?? 0,
      descontoPerc:       data.descontoPerc       ?? 0,
      descontoValor:      data.descontoValor      ?? 0,
      ivaPerc:            data.ivaPerc            ?? 0,
      ivaValor:           data.ivaValor           ?? 0,

      requerente:  data.requerente,
      contacto:    data.contacto,
      observacoes: data.observacoes ?? null,

      statusHistory: {
        create: { status: OrderStatus.PENDING, changedById: userId, notes: 'Encomenda criada' },
      },
    },
    include: { customer: { select: { id: true, name: true } } },
  })
}

// ── Atualizar ────────────────────────────────────────────────────────────────
export async function updateOrder(id: string, data: UpdateOrderInput, userId: string) {
  const existing = await prisma.order.findUnique({ where: { id } })
  if (!existing) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  if (existing.status === OrderStatus.PAID) {
    throw { statusCode: 400, message: 'Não é possível editar uma encomenda já paga' }
  }

  // Recalcular extrasValor se extras for fornecido
  const updateData: any = { ...data, updatedAt: new Date() }
  if (data.extras !== undefined) {
    updateData.extrasValor = data.extras.reduce((sum, e) => sum + e.valor, 0)
  }
  // Sincronizar fotoPessoa com o primeiro elemento de fotosPessoa
  if (data.fotosPessoa !== undefined) {
    updateData.fotoPessoa = data.fotosPessoa.length > 0 ? data.fotosPessoa[0] : null
  }

  return prisma.order.update({
    where: { id },
    data:  updateData,
    include: { customer: { select: { id: true, name: true } } },
  })
}

// ── Atualizar estado ─────────────────────────────────────────────────────────
export async function updateOrderStatus(id: string, data: UpdateStatusInput, userId: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  if (order.status === data.status)
    throw { statusCode: 400, message: 'A encomenda já se encontra neste estado' }

  const [updated] = await prisma.$transaction([
    prisma.order.update({ where: { id }, data: { status: data.status } }),
    prisma.orderStatusHistory.create({
      data: {
        orderId:     id,
        status:      data.status,
        changedById: userId,
        notes:       data.notes,
        fotos:       data.fotos ?? [],
      },
    }),
  ])
  return updated
}

// ── Histórico ────────────────────────────────────────────────────────────────
export async function getOrderHistory(id: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  return prisma.orderStatusHistory.findMany({
    where: { orderId: id },
    include: { changedBy: { select: { id: true, name: true } } },
    orderBy: { createdAt: 'desc' },
  })
}

// ── Cancelar ─────────────────────────────────────────────────────────────────
export async function cancelOrder(id: string, userId: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  if (order.status === OrderStatus.CANCELLED)
    throw { statusCode: 400, message: 'A encomenda já está cancelada' }
  if (order.status === OrderStatus.PAID)
    throw { statusCode: 400, message: 'Não é possível cancelar uma encomenda já paga' }

  const [updated] = await prisma.$transaction([
    prisma.order.update({ where: { id }, data: { status: OrderStatus.CANCELLED } }),
    prisma.orderStatusHistory.create({
      data: { orderId: id, status: OrderStatus.CANCELLED, changedById: userId, notes: 'Encomenda cancelada' },
    }),
  ])
  return updated
}

// ── Eliminar ─────────────────────────────────────────────────────────────────
export async function deleteOrder(id: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }

  // Só permite eliminar a encomenda mais recente para evitar lacunas na numeração
  const newerOrder = await prisma.order.findFirst({
    where: { createdAt: { gt: order.createdAt } },
    select: { orderNumber: true },
  })
  if (newerOrder) {
    throw {
      statusCode: 409,
      message: `Não é possível eliminar esta encomenda. Existe a encomenda ${newerOrder.orderNumber} criada depois. Só a encomenda mais recente pode ser eliminada para não criar lacunas na numeração.`,
    }
  }

  await prisma.order.delete({ where: { id } })
  return { success: true }
}
