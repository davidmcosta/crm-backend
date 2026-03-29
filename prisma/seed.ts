import { PrismaClient, UserRole } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 A criar dados iniciais...')

  // Criar utilizador Admin
  const adminPassword = await bcrypt.hash('admin123', 10)
  const admin = await prisma.user.upsert({
    where: { email: 'admin@empresa.pt' },
    update: {},
    create: {
      name: 'Administrador',
      email: 'admin@empresa.pt',
      password: adminPassword,
      role: UserRole.ADMIN,
    },
  })
  console.log(`✅ Admin criado: ${admin.email}`)

  // Criar utilizador Operador de exemplo
  const operatorPassword = await bcrypt.hash('operador123', 10)
  const operator = await prisma.user.upsert({
    where: { email: 'operador@empresa.pt' },
    update: {},
    create: {
      name: 'Operador Exemplo',
      email: 'operador@empresa.pt',
      password: operatorPassword,
      role: UserRole.OPERATOR,
    },
  })
  console.log(`✅ Operador criado: ${operator.email}`)

  // Criar alguns clientes de exemplo
  const customer1 = await prisma.customer.upsert({
    where: { id: 'seed-customer-1' },
    update: {},
    create: {
      id: 'seed-customer-1',
      name: 'Empresa ABC Lda',
      email: 'geral@empresaabc.pt',
      phone: '912345678',
      address: 'Rua das Flores, 123, Lisboa',
      taxId: '509876543',
    },
  })

  const customer2 = await prisma.customer.upsert({
    where: { id: 'seed-customer-2' },
    update: {},
    create: {
      id: 'seed-customer-2',
      name: 'João Silva',
      email: 'joao.silva@email.com',
      phone: '961234567',
      taxId: '123456789',
    },
  })
  console.log(`✅ Clientes criados: ${customer1.name}, ${customer2.name}`)

  console.log('\n🎉 Seed concluído com sucesso!')
  console.log('\nCredenciais de acesso:')
  console.log('  Admin:    admin@empresa.pt    / admin123')
  console.log('  Operador: operador@empresa.pt / operador123')
  console.log('\n⚠️  Muda as passwords após o primeiro login!')
}

main()
  .catch((e) => {
    console.error('❌ Erro no seed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
