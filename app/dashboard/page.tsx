import { auth } from '@/auth'
import { redirect } from 'next/navigation'
import { getRemembralls, createRemembrall } from '@/app/actions/remembrall'
import Link from 'next/link'

export default async function Dashboard() {
  const session = await auth()
  if (!session?.user) redirect('/')

  const remembralls = await getRemembralls()

  async function handleCreate() {
    'use server'
    const r = await createRemembrall('New Remembrall')
    redirect(`/remembrall/${r.id}/edit`)
  }

  return (
    <main style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>My Remembralls</h1>
      <form action={handleCreate}>
        <button type="submit">+ New Remembrall</button>
      </form>
      <ul style={{ marginTop: '1rem' }}>
        {remembralls.map((r) => (
          <li key={r.id} style={{ marginBottom: '0.5rem' }}>
            <Link href={`/remembrall/${r.id}`}>{r.title}</Link>
            {' · '}
            <Link href={`/remembrall/${r.id}/edit`}>Edit</Link>
          </li>
        ))}
      </ul>
      {remembralls.length === 0 && (
        <p style={{ color: '#888' }}>No Remembralls yet. Create one above.</p>
      )}
    </main>
  )
}
