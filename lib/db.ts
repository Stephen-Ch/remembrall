import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export async function dbForUser<T>(
  userId: string,
  fn: (tx: Omit<PrismaClient, '$connect' | '$disconnect' | '$on' | '$transaction' | '$use' | '$extends'>) => Promise<T>
): Promise<T> {
  return prisma.$transaction(async (tx) => {
    await tx.$executeRaw`SELECT set_config('app.current_user_id', ${userId}, TRUE)`
    return fn(tx)
  })
}

export { prisma }