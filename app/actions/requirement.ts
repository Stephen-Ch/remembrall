'use server'

import { auth } from '@/auth'
import { dbForUser } from '@/lib/db'
import { checkNestingSafe } from '@/lib/nesting'

async function requireSession() {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')
  return session.user.id
}

export async function addRequirement(remembrallId: string, text: string) {
  const userId = await requireSession()
  return dbForUser(userId, async (tx) => {
    // Get current max order
    const last = await tx.requirement.findFirst({
      where: { remembrallId },
      orderBy: { order: 'desc' },
      select: { order: true },
    })
    return tx.requirement.create({
      data: {
        remembrallId,
        text,
        order: (last?.order ?? -1) + 1,
      },
    })
  })
}

export async function updateRequirement(
  id: string,
  data: { text?: string; order?: number }
) {
  const userId = await requireSession()
  return dbForUser(userId, (tx) =>
    tx.requirement.update({ where: { id }, data })
  )
}

export async function deleteRequirement(id: string) {
  const userId = await requireSession()
  return dbForUser(userId, (tx) =>
    tx.requirement.delete({ where: { id } })
  )
}

export async function reorderRequirements(
  remembrallId: string,
  orderedIds: string[]
) {
  const userId = await requireSession()
  return dbForUser(userId, async (tx) => {
    await Promise.all(
      orderedIds.map((id, index) =>
        tx.requirement.update({ where: { id }, data: { order: index } })
      )
    )
  })
}

export async function setNestedRemembrall(
  requirementId: string,
  targetRemembrallId: string | null
) {
  const userId = await requireSession()

  if (targetRemembrallId !== null) {
    // Get the parent remembrallId for this requirement
    const req = await dbForUser(userId, (tx) =>
      tx.requirement.findUnique({
        where: { id: requirementId },
        select: { remembrallId: true },
      })
    )
    if (!req) throw new Error('Requirement not found')

    const check = await checkNestingSafe(
      req.remembrallId,
      targetRemembrallId,
      userId
    )
    if (!check.ok) throw new Error(check.reason)
  }

  return dbForUser(userId, (tx) =>
    tx.requirement.update({
      where: { id: requirementId },
      data: { nestedRemembrallId: targetRemembrallId },
    })
  )
}
