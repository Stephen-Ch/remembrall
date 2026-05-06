'use client'

import { useState } from 'react'
import Link from 'next/link'

interface Requirement {
  id: string
  text: string
  order: number
  nestedRemembrall: { id: string; title: string; slug: string } | null
}

interface Props {
  requirements: Requirement[]
  remembrallId: string
}

export default function ChecklistRunner({ requirements }: Props) {
  const [checked, setChecked] = useState<Record<string, boolean>>({})

  return (
    <ul style={{ marginTop: '1.5rem', listStyle: 'none', padding: 0 }}>
      {requirements.map((req) => (
        <li key={req.id} style={{ marginBottom: '0.75rem' }}>
          <label style={{ display: 'flex', alignItems: 'flex-start', gap: '0.5rem', cursor: 'pointer' }}>
            <input
              type="checkbox"
              checked={!!checked[req.id]}
              onChange={(e) =>
                setChecked((prev) => ({ ...prev, [req.id]: e.target.checked }))
              }
            />
            <span style={{ textDecoration: checked[req.id] ? 'line-through' : 'none' }}>
              {req.text}
            </span>
          </label>
          {req.nestedRemembrall && (
            <div style={{ marginLeft: '1.5rem', marginTop: '0.25rem' }}>
              <Link href={`/remembrall/${req.nestedRemembrall.id}`}>
                ↳ {req.nestedRemembrall.title}
              </Link>
            </div>
          )}
        </li>
      ))}
      {requirements.length === 0 && (
        <p style={{ color: '#888' }}>No requirements yet.</p>
      )}
    </ul>
  )
}
