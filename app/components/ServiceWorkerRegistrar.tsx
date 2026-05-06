'use client'

import { useEffect } from 'react'
import { initSyncOnReconnect } from '@/lib/sync'

export default function ServiceWorkerRegistrar() {
  useEffect(() => {
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/sw.js').catch(console.error)
    }
    initSyncOnReconnect()
  }, [])

  return null
}
