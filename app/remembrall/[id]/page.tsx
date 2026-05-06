import { auth } from '@/auth'
import { redirect } from 'next/navigation'
import { getRemembrall } from '@/app/actions/remembrall'
import Link from 'next/link'
import ChecklistRunner from '@/app/remembrall/[id]/ChecklistRunner'

interface Props {
  params: { id: string }
}

export default async function RemembrallPage({ params }: Props) {
  const session = await auth()
  if (!session?.user) redirect('/')

  const remembrall = await getRemembrall(params.id)
  if (!remembrall) redirect('/dashboard')

  return (
    <main style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <Link href="/dashboard">← Dashboard</Link>
      <h1 style={{ marginTop: '1rem' }}>{remembrall.title}</h1>
      <Link href={`/remembrall/${remembrall.id}/edit`}>Edit</Link>
      <ChecklistRunner requirements={remembrall.requirements} remembrallId={remembrall.id} />
    </main>
  )
}
