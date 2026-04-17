import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const UserRole = { ADMIN: 'ADMIN', MANAGER: 'MANAGER', OPERATOR: 'OPERATOR', VIEWER: 'VIEWER' } as const

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 A criar dados iniciais...')

  // Criar Master Admin (conta especial com poderes totais)
  const masterPassword = await bcrypt.hash('master123', 10)
  const master = await prisma.user.upsert({
    where: { username: 'master' },
    update: {},
    create: {
      name:     'Master Admin',
      username: 'master',
      password: masterPassword,
      role:     UserRole.ADMIN,
      isMaster: true,
    },
  })
  console.log(`✅ Master Admin criado: ${master.username}`)

  console.log('\n🎉 Seed concluído com sucesso!')
  console.log('\nCredenciais de acesso:')
  console.log('  Master Admin: master / master123')
  console.log('\n⚠️  Muda a password após o primeiro login!')
}

main()
  .catch((e) => {
    console.error('❌ Erro no seed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
