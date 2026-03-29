import { FastifyRequest, FastifyReply } from 'fastify'

// Garante que o utilizador está autenticado
export async function authenticate(request: FastifyRequest, reply: FastifyReply) {
  try {
    await request.jwtVerify()
  } catch (err) {
    return reply.status(401).send({
      error: 'Não autorizado',
      message: 'Token inválido ou expirado. Faz login novamente.',
    })
  }
}
