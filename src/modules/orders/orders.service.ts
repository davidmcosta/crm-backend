import { PrismaClient, OrderStatus } from '@prisma/client'
import { CreateOrderInput, UpdateOrderInput, UpdateStatusInput, ListOrdersQuery } from './orders.schema'

const prisma = new PrismaClient()

// Gera número de encomenda único: ORD-2024-00001
async function generateOrderNumber(): Promise<string> {
  const year = new Date().getFullYear()
  const prefix = `ORD-${year}-`

  const lastOrder = await prisma.order.findFirst({
    where: { orderNumber: { startsWith: prefix } },
    orderBy: { orderNumber: 'desc' },
    select: { orderNumber: true },
  })

  let nextNumber = 1
  if (lastOrder) {
    const lastNum = parseInt(lastOrder.orderNumber.split('-')[2], 10)
    nextNumber = lastNum + 1
  }

  return `${prefix}${String(nextNumber).padStart(5, '0')}`
}

// Recalcula o total da encomenda com base nos itens
function calculateTotal(items: { quantity: number; unitPrice: number }[]): number {
  return items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0)
}

export async function listOrders(query: ListOrdersQuery) {
  const { page, limit, status, customerId, search } = query
  const skip = (page - 1) * limit

  const where: any = {}
  if (status) where.status = status
  if (customerId) where.customerId = customerId
  if (search) {
    where.OR = [
      { orderNumber: { contains: search, mode: 'insensitive' } },
      { customer: { name: { contains: search, mode: 'insensitive' } } },
    ]
  }

  const [orders, total] = await Promise.all([
    prisma.order.findMany({
      where,
      skip,
      take: limit,
      orderBy: { createdAt: 'desc' },
      include: {
        customer: { select: { id: true, name: true, email: true } },
        createdBy: { select: { id: true, name: true } },
        items: true,
        _count: { select: { items: true } },
      },
    }),
    prisma.order.count({ where }),
  ])

  return {
    data: orders,
    pagination: {
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    },
  }
}

export async function getOrderById(id: string) {
  const order = await prisma.order.findUnique({
    where: { id },
    include: {
      customer: true,
      createdBy: { select: { id: true, name: true, email: true } },
      items: true,
      statusHistory: {
        include: { changedBy: { select: { id: true, name: true } } },
        orderBy: { createdAt: 'desc' },
      },
    },
  })

  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }
  return order
}

export async function createOrder(data: CreateOrderInput, userId: string) {
  // Verificar se o cliente existe
  const customer = await prisma.customer.findUnique({ where: { id: data.customerId } })
  if (!customer) throw { statusCode: 404, message: 'Cliente não encontrado' }

  const orderNumber = await generateOrderNumber()
  const totalAmount = calculateTotal(data.items)

  const order = await prisma.order.create({
    data: {
      orderNumber,
      customerId: data.customerId,
      createdById: userId,
      notes: data.notes,
      expectedDate: data.expectedDate ? new Date(data.expectedDate) : null,
      totalAmount,
      status: OrderStatus.PENDING,
      items: {
        create: data.items.map((item) => ({
          productName: item.productName,
          description: item.description,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          totalPrice: item.quantity * item.unitPrice,
        })),
      },
      statusHistory: {
        create: {
          status: OrderStatus.PENDING,
          changedById: userId,
          notes: 'Encomenda criada',
        },
      },
    },
    include: {
      customer: { select: { id: true, name: true } },
      items: true,
    },
  })

  return order
}

export async function updateOrder(id: string, data: UpdateOrderInput, userId: string) {
  const existing = await prisma.order.findUnique({ where: { id } })
  if (!existing) throw { statusCode: 404, message: 'Encomenda não encontrada' }

  if ([OrderStatus.DELIVERED, OrderStatus.CANCELLED].includes(existing.status)) {
    throw { statusCode: 400, message: 'Não é possível editar uma encomenda entregue ou cancelada' }
  }

  const updateData: any = {
    notes: data.notes,
    updatedAt: new Date(),
  }

  if (data.expectedDate) {
    updateData.expectedDate = new Date(data.expectedDate)
  }

  if (data.items) {
    const totalAmount = calculateTotal(data.items)
    updateData.totalAmount = totalAmount

    // Substituir os itens existentes
    await prisma.orderItem.deleteMany({ where: { orderId: id } })
    updateData.items = {
      create: data.items.map((item) => ({
        productName: item.productName,
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        totalPrice: item.quantity * item.unitPrice,
      })),
    }
  }

  return prisma.order.update({
    where: { id },
    data: updateData,
    include: { items: true, customer: { select: { id: true, name: true } } },
  })
}

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
    prisma.order.update({
      where: { id },
      data: { status: data.status },
    }),
    prisma.orderStatusHistory.create({
      data: {
        orderId: id,
        status: data.status,
        changedById: userId,
        notes: data.notes,
      },
    }),
  ])

  return updatedOrder
}

export async function getOrderHistory(id: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }

  return prisma.orderStatusHistory.findMany({
    where: { orderId: id },
    include: { changedBy: { select: { id: true, name: true } } },
    orderBy: { createdAt: 'desc' },
  })
}

export async function cancelOrder(id: string, userId: string) {
  const order = await prisma.order.findUnique({ where: { id } })
  if (!order) throw { statusCode: 404, message: 'Encomenda não encontrada' }

  if (order.status === OrderStatus.DELIVERED) {
    throw { statusCode: 400, message: 'Não é possível cancelar uma encomenda já entregue' }
  }

  if (order.status === OrderStatus.CANCELLED) {
    throw { statusCode: 400, message: 'A encomenda já está cancelada' }
  }

  const [updatedOrder] = await prisma.$transaction([
    prisma.order.update({
      where: { id },
      data: { status: OrderStatus.CANCELLED },
    }),
    prisma.orderStatusHistory.create({
      data: {
        orderId: id,
        status: OrderStatus.CANCELLED,
        changedById: userId,
        notes: 'Encomenda cancelada',
      },
    }),
  ])

  return updatedOrder
}
