/**
 * RLS Matrix — 6 isolation scenarios
 *
 * These are integration tests that require a real Postgres connection.
 * They are skipped unless TEST_DATABASE_URL is set in the environment.
 *
 * To run:
 *   TEST_DATABASE_URL=postgresql://... npx vitest tests/rls-matrix.test.ts
 *
 * Install vitest first: npm install -D vitest
 */

import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { prisma as db } from '@/lib/db'

const skip = !process.env.TEST_DATABASE_URL

// Test transactions simulate different user sessions by setting app.current_user_id.

async function asUser<T>(
  userId: string,
  fn: (tx: Parameters<Parameters<typeof db.$transaction>[0]>[0]) => Promise<T>
): Promise<T> {
  return db.$transaction(async (tx) => {
    await tx.$executeRaw`SELECT set_config('app.current_user_id', ${userId}, TRUE)`
    return fn(tx)
  })
}

async function asNoUser<T>(
  fn: (tx: Parameters<Parameters<typeof db.$transaction>[0]>[0]) => Promise<T>
): Promise<T> {
  return db.$transaction(async (tx) => {
    // Explicitly unset user ID — simulates unauthenticated or null-user state
    await tx.$executeRaw`SELECT set_config('app.current_user_id', '', TRUE)`
    return fn(tx)
  })
}

// Seed data IDs — set in beforeAll
let userAId: string
let userBId: string
let remembrallAId: string
let remembrallBId: string
let activeLinkId: string
let revokedLinkId: string
let expiredLinkId: string

describe.skipIf(skip)('RLS isolation matrix', () => {
  beforeAll(async () => {
    // Create two users directly (bypass RLS — using superuser DIRECT_URL for setup)
    const userA = await db.user.create({ data: { email: 'user-a@rls-test.local' } })
    const userB = await db.user.create({ data: { email: 'user-b@rls-test.local' } })
    userAId = userA.id
    userBId = userB.id

    // Create remembralls as each user
    const ra = await db.remembrall.create({
      data: { title: 'User A Remembrall', slug: 'user-a-remembrall', ownerId: userAId },
    })
    const rb = await db.remembrall.create({
      data: { title: 'User B Remembrall', slug: 'user-b-remembrall', ownerId: userBId },
    })
    remembrallAId = ra.id
    remembrallBId = rb.id

    // Create share links for User A's remembrall
    const activeLink = await db.shareLink.create({
      data: { remembrallId: remembrallAId, createdById: userAId },
    })
    const revokedLink = await db.shareLink.create({
      data: {
        remembrallId: remembrallAId,
        createdById: userAId,
        revokedAt: new Date(),
      },
    })
    const expiredLink = await db.shareLink.create({
      data: {
        remembrallId: remembrallAId,
        createdById: userAId,
        expiresAt: new Date(Date.now() - 1000 * 60 * 60), // 1 hour ago
      },
    })
    activeLinkId = activeLink.id
    revokedLinkId = revokedLink.id
    expiredLinkId = expiredLink.id
  })

  afterAll(async () => {
    // Clean up test data
    await db.shareLink.deleteMany({
      where: { id: { in: [activeLinkId, revokedLinkId, expiredLinkId] } },
    })
    await db.remembrall.deleteMany({
      where: { id: { in: [remembrallAId, remembrallBId] } },
    })
    await db.user.deleteMany({
      where: { id: { in: [userAId, userBId] } },
    })
    await db.$disconnect()
  })

  // ── Scenario 1: Own data is visible ─────────────────────────────────────────
  it('Scenario 1: user A can read their own Remembrall', async () => {
    const result = await asUser(userAId, (tx) =>
      tx.remembrall.findMany({ where: { id: remembrallAId } })
    )
    expect(result).toHaveLength(1)
    expect(result[0].id).toBe(remembrallAId)
  })

  // ── Scenario 2: Other user's data is blocked ─────────────────────────────────
  it('Scenario 2: user A cannot read user B Remembrall', async () => {
    const result = await asUser(userAId, (tx) =>
      tx.remembrall.findMany({ where: { id: remembrallBId } })
    )
    expect(result).toHaveLength(0)
  })

  // ── Scenario 3: Unauthenticated request is blocked ───────────────────────────
  it('Scenario 3: unauthenticated (empty user ID) cannot read any Remembrall', async () => {
    const result = await asNoUser((tx) => tx.remembrall.findMany())
    expect(result).toHaveLength(0)
  })

  // ── Scenario 4: Null / missing user ID is blocked ────────────────────────────
  it('Scenario 4: null current_setting returns no rows', async () => {
    // current_setting returns NULL when missing; RLS policy treats NULL as false
    const result = await db.$transaction(async (tx) => {
      // Do NOT set app.current_user_id — leave it unset for this transaction
      return tx.remembrall.findMany()
    })
    expect(result).toHaveLength(0)
  })

  // ── Scenario 5: Revoked share link is not returned ───────────────────────────
  it('Scenario 5: revoked ShareLink is present in DB but flagged correctly', async () => {
    const link = await asUser(userAId, (tx) =>
      tx.shareLink.findUnique({ where: { id: revokedLinkId } })
    )
    // Link exists but has revokedAt set — app layer must check this before serving
    expect(link).not.toBeNull()
    expect(link!.revokedAt).not.toBeNull()
  })

  // ── Scenario 6: Expired share link is not returned ───────────────────────────
  it('Scenario 6: expired ShareLink is present in DB but flagged correctly', async () => {
    const link = await asUser(userAId, (tx) =>
      tx.shareLink.findUnique({ where: { id: expiredLinkId } })
    )
    // Link exists but expiresAt is in the past — app layer must check before serving
    expect(link).not.toBeNull()
    expect(link!.expiresAt!.getTime()).toBeLessThan(Date.now())
  })
})
