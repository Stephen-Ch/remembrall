// Client-side only — handles syncing pending offline check states when back online.

import { getPendingSync, markSynced } from '@/lib/offline-store'

export function initSyncOnReconnect() {
  if (typeof window === 'undefined') return

  async function syncPending() {
    const pending = await getPendingSync()
    if (pending.length === 0) return

    await Promise.allSettled(
      pending.map(async ({ requirementId, checked }) => {
        try {
          const res = await fetch('/api/sync', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ requirementId, checked }),
          })
          if (res.ok) await markSynced(requirementId)
        } catch {
          // Will retry next time we come online
        }
      })
    )
  }

  window.addEventListener('online', syncPending)

  // Also attempt sync on load if already online
  if (navigator.onLine) syncPending()
}
