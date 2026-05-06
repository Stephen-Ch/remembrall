import { NextRequest, NextResponse } from 'next/server'
import { auth } from '@/auth'
import { dbForUser } from '@/lib/db'

export async function POST(req: NextRequest) {
  const session = await auth()
  if (!session?.user?.id) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const { requirementId, checked } = await req.json()
  if (!requirementId || typeof checked !== 'boolean') {
    return NextResponse.json({ error: 'Invalid payload' }, { status: 400 })
  }

  await dbForUser(session.user.id, (tx) =>
    tx.requirement.update({ where: { id: requirementId }, data: { checked } })
  )

  return NextResponse.json({ ok: true })
}
