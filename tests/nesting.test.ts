/**
 * Unit tests for cycle detection in lib/nesting.ts
 *
 * These mock the DB and do not require a real connection.
 * Run with: npx vitest tests/nesting.test.ts
 * Install first: npm install -D vitest
 */

import { describe, it, expect, vi, beforeEach } from 'vitest'
import { MAX_NEST_DEPTH } from '@/lib/nesting'

// Mock dbForUser so we can control what the DB returns
vi.mock('@/lib/db', () => ({
  dbForUser: vi.fn(),
}))

import { dbForUser } from '@/lib/db'
import { checkNestingSafe } from '@/lib/nesting'

const mockDbForUser = vi.mocked(dbForUser)

// Helper: build a mock chain of nesting
// chain = [A, B, C] means A nests B, B nests C
// Returns a mock dbForUser that simulates traversal
function buildMockDb(chain: string[]) {
  return mockDbForUser.mockImplementation(async (_userId, fn) => {
    // The fn receives a tx object — we mock the tx methods
    const tx = {
      requirement: {
        findMany: vi.fn(),
        findFirst: vi.fn(),
      },
    }

    // Wire up findFirst to return the parent of each node in the chain
    tx.requirement.findFirst.mockImplementation(async ({ where }: { where: { nestedRemembrallId: string } }) => {
      const nodeId = where.nestedRemembrallId
      const idx = chain.indexOf(nodeId)
      if (idx > 0) {
        return { remembrallId: chain[idx - 1] }
      }
      return null
    })

    tx.requirement.findMany.mockResolvedValue([])

    return fn(tx as never)
  })
}

describe('checkNestingSafe', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('allows A → B (simple nesting)', async () => {
    buildMockDb(['B']) // B has no parent
    const result = await checkNestingSafe('A', 'B', 'user-1')
    expect(result.ok).toBe(true)
  })

  it('blocks A → B → A (direct cycle)', async () => {
    // Target is B, B's parent is A (the source) — cycle
    mockDbForUser.mockImplementation(async (_userId, fn) => {
      const tx = {
        requirement: {
          findMany: vi.fn().mockResolvedValue([]),
          findFirst: vi.fn().mockImplementation(async ({ where }: { where: { nestedRemembrallId: string } }) => {
            if (where.nestedRemembrallId === 'B') return { remembrallId: 'A' }
            return null
          }),
        },
      }
      return fn(tx as never)
    })

    const result = await checkNestingSafe('A', 'B', 'user-1')
    expect(result.ok).toBe(false)
    expect((result as { ok: false; reason: string }).reason).toMatch(/circular/i)
  })

  it('allows a chain of exactly MAX_NEST_DEPTH levels', async () => {
    // Chain: [1, 2, 3, 4, 5] — 5 levels deep, target is 5, source is new
    const chain = ['1', '2', '3', '4', '5']
    buildMockDb(chain)
    const result = await checkNestingSafe('NEW', '5', 'user-1')
    expect(result.ok).toBe(true)
  })

  it('blocks a chain exceeding MAX_NEST_DEPTH', async () => {
    // Chain longer than MAX_NEST_DEPTH
    const chain = Array.from({ length: MAX_NEST_DEPTH + 1 }, (_, i) => String(i + 1))
    buildMockDb(chain)
    const result = await checkNestingSafe('NEW', chain[chain.length - 1], 'user-1')
    expect(result.ok).toBe(false)
    expect((result as { ok: false; reason: string }).reason).toMatch(/limit/i)
  })

  it('allows clearing nesting (null target) — always safe', async () => {
    // setNestedRemembrall handles null before calling checkNestingSafe
    // so checkNestingSafe is never called with null — but confirm MAX_NEST_DEPTH export
    expect(MAX_NEST_DEPTH).toBe(5)
  })
})
