import { auth } from '@/auth'
import { redirect } from 'next/navigation'
import Link from 'next/link'

export default async function Home() {
  const session = await auth()
  if (session?.user) redirect('/dashboard')

  return (
    <main style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>Remembrall</h1>
      <p>Interactive checklists for things that matter.</p>
      <Link href="/api/auth/signin">Sign in</Link>
    </main>
  )
}
