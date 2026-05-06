'use client'

import { useState, useEffect } from 'react'

export default function OfflineIndicator() {
  const [online, setOnline] = useState(true)

  useEffect(() => {
    setOnline(navigator.onLine)
    const handleOnline = () => setOnline(true)
    const handleOffline = () => setOnline(false)
    window.addEventListener('online', handleOnline)
    window.addEventListener('offline', handleOffline)
    return () => {
      window.removeEventListener('online', handleOnline)
      window.removeEventListener('offline', handleOffline)
    }
  }, [])

  if (online) return null

  return (
    <div style={{
      position: 'fixed',
      bottom: '1rem',
      left: '50%',
      transform: 'translateX(-50%)',
      background: '#333',
      color: '#fff',
      padding: '0.5rem 1rem',
      borderRadius: '4px',
      fontSize: '0.875rem',
    }}>
      Offline — changes will sync when reconnected
    </div>
  )
}
