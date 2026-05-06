/**
 * TEST-ONLY auth endpoint.
 * Creates a real database session for a test user without requiring email.
 *
 * ONLY active when PLAYWRIGHT_TEST_MODE=true.
 * Returns 404 in all other environments.
 */
import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/lib/db'
import { randomUUID } from 'crypto'

export async function POST(req: NextRequest) {
  if (process.env.PLAYWRIGHT_TEST_MODE !== 'true') {
    return NextResponse.json({ error: 'Not found' }, { status: 404 })
  }

  const { email } = await req.json()
  if (!email) return NextResponse.json({ error: 'email required' }, { status: 400 })

  // Upsert test user
  const user = await prisma.user.upsert({
    where: { email },
    update: {},
    create: { email },
  })

  // Create a session
  const sessionToken = randomUUID()
  const expires = new Date(Date.now() + 1000 * 60 * 60 * 24) // 24h

  await prisma.session.create({
    data: { sessionToken, userId: user.id, expires },
  })

  const response = NextResponse.json({ ok: true, userId: user.id })
  response.cookies.set('authjs.session-token', sessionToken, {
    httpOnly: true,
    expires,
    path: '/',
    sameSite: 'lax',
  })
  return response
}
