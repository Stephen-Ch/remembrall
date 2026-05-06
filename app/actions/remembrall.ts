'use server'

import { auth } from '@/auth'
import { dbForUser } from '@/lib/db'
import { createId } from '@/lib/ids'

function slugify(title: string, id: string): string {
  const base = title
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .slice(0, 80)
  // Append short suffix for uniqueness
  return `${base}-${id.slice(-6)}`
}

async function requireSession() {
  const session = await auth()
  if (!session?.user?.id) throw new Error('Unauthorized')
  return session.user.id
}

export async function createRemembrall(title: string) {
  const userId = await requireSession()
  const id = createId()
  const slug = slugify(title, id)

  return dbForUser(userId, (tx) =>
    tx.remembrall.create({
      data: { id, title, slug, ownerId: userId },
    })
  )
}

export async function getRemembralls() {
  const userId = await requireSession()
  return dbForUser(userId, (tx) =>
    tx.remembrall.findMany({
      orderBy: { createdAt: 'desc' },
    })
  )
}

export async function getRemembrall(id: string) {
  const userId = await requireSession()
  return dbForUser(userId, (tx) =>
    tx.remembrall.findUnique({
      where: { id },
      include: {
        requirements: {
          orderBy: { order: 'asc' },
          include: { nestedRemembrall: { select: { id: true, title: true, slug: true } } },
        },
      },
    })
  )
}

export async function updateRemembrall(id: string, data: { title?: string }) {
  const userId = await requireSession()
  return dbForUser(userId, (tx) =>
    tx.remembrall.update({
      where: { id },
      data,
    })
  )
}

export async function deleteRemembrall(id: string) {
  const userId = await requireSession()
  return dbForUser(userId, (tx) =>
    tx.remembrall.delete({ where: { id } })
  )
}
