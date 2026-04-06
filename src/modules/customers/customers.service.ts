import { PrismaClient } from '@prisma/client'
import { CreateCustomerInput, UpdateCustomerInput, ListCustomersQuery } from './customers.schema'

const prisma = new PrismaClient()

export async function listCustomers(query: ListCustomersQuery) {
  const { page, limit, search } = query
  const skip = (page - 1) * limit

  const where: any = { active: true }
  if (search) {
    where.OR = [
      { name: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
      { phone: { contains: search, mode: 'insensitive' } },
      { taxId: { contains: search, mode: 'insensitive' } },
    ]
  }

  const [customers, total] = await Promise.all([
    prisma.customer.findMany({
      where,
      skip,
      take: limit,
      orderBy: { name: 'asc' },
      include: { _count: { select: { orders: true } } },
    }),
    prisma.customer.count({ where }),
  ])

  return {
    data: customers,
    pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
  }
}

export async function getCustomerById(id: string) {
  const customer = await prisma.customer.findUnique({
    where: { id },
    include: { _count: { select: { orders: true } } },
  })
  if (!customer || !customer.isActive) {
    throw { statusCode: 404, message: 'Cliente não encontrado' }
  }
  return customer
}

export async function getCustomerOrders(id: string) {
  const customer = await prisma.customer.findUnique({ where: { id } })
  if (!customer) throw { statusCode: 404, message: 'Cliente não encontrado' }

  return prisma.order.findMany({
    where: { customerId: id },
    orderBy: { createdAt: 'desc' },
    include: {
      createdBy: { select: { id: true, name: true } },
    },
  })
}

export async function createCustomer(data: CreateCustomerInput) {
  return prisma.customer.create({ data })
}

export async function updateCustomer(id: string, data: UpdateCustomerInput) {
  const customer = await prisma.customer.findUnique({ where: { id } })
  if (!customer || !customer.isActive) {
    throw { statusCode: 404, message: 'Cliente não encontrado' }
  }
  return prisma.customer.update({ where: { id }, data })
}
