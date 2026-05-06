import { dbForUser } from '@/lib/db'

export const MAX_NEST_DEPTH = 5

/**
 * Check whether setting nestedRemembrallId = targetId on a Requirement
 * inside sourceRemembrallId would create a cycle or exceed MAX_NEST_DEPTH.
 *
 * Traverses upward from targetRemembrallId through its own Requirements'
 * nestedRemembrallId links. If sourceRemembrallId appears in the chain,
 * it would create a cycle. If the chain is too long, it would exceed the depth limit.
 */
export async function checkNestingSafe(
  sourceRemembrallId: string,
  targetRemembrallId: string,
  userId: string
): Promise<{ ok: true } | { ok: false; reason: string }> {
  const visited = new Set<string>()
  let currentId: string | null = targetRemembrallId
  let depth = 0

  while (currentId !== null) {
    if (currentId === sourceRemembrallId) {
      return { ok: false, reason: 'This would create a circular reference.' }
    }
    if (visited.has(currentId)) {
      // Unexpected cycle in existing data — stop safely
      return { ok: false, reason: 'Circular reference detected in existing data.' }
    }
    if (depth >= MAX_NEST_DEPTH) {
      return { ok: false, reason: `Nesting is limited to ${MAX_NEST_DEPTH} levels.` }
    }

    visited.add(currentId)

    // Find the first nested remembrall that this remembrall's requirements point to
    // (i.e., climb upward in the chain)
    const requirements = await dbForUser(userId, (tx) =>
      tx.requirement.findMany({
        where: {
          remembrallId: currentId!,
          nestedRemembrallId: { not: null },
        },
        select: { nestedRemembrallId: true },
      })
    )

    // For cycle detection we need to traverse all branches — check each
    // If any branch would create a cycle, reject
    for (const req of requirements) {
      if (req.nestedRemembrallId === sourceRemembrallId) {
        return { ok: false, reason: 'This would create a circular reference.' }
      }
    }

    // Move to the parent: find what remembrall nests this one
    const parent = await dbForUser(userId, (tx) =>
      tx.requirement.findFirst({
        where: { nestedRemembrallId: currentId! },
        select: { remembrallId: true },
      })
    )

    currentId = parent?.remembrallId ?? null
    depth++
  }

  return { ok: true }
}
