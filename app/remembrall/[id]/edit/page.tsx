import { auth } from '@/auth'
import { redirect } from 'next/navigation'
import { getRemembrall, updateRemembrall, deleteRemembrall } from '@/app/actions/remembrall'
import { addRequirement, deleteRequirement, reorderRequirements } from '@/app/actions/requirement'
import Link from 'next/link'

interface Props {
  params: { id: string }
}

export default async function EditPage({ params }: Props) {
  const session = await auth()
  if (!session?.user) redirect('/')

  const remembrall = await getRemembrall(params.id)
  if (!remembrall) redirect('/dashboard')

  async function handleUpdateTitle(formData: FormData) {
    'use server'
    const title = formData.get('title') as string
    await updateRemembrall(params.id, { title })
    redirect(`/remembrall/${params.id}/edit`)
  }

  async function handleDelete() {
    'use server'
    await deleteRemembrall(params.id)
    redirect('/dashboard')
  }

  async function handleAddRequirement(formData: FormData) {
    'use server'
    const text = formData.get('text') as string
    if (text?.trim()) await addRequirement(params.id, text.trim())
    redirect(`/remembrall/${params.id}/edit`)
  }

  return (
    <main style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <Link href={`/remembrall/${params.id}`}>← Back to {remembrall.title}</Link>

      <h1 style={{ marginTop: '1rem' }}>Edit</h1>

      {/* Title */}
      <form action={handleUpdateTitle} style={{ marginBottom: '1.5rem' }}>
        <label>
          Title
          <input
            name="title"
            defaultValue={remembrall.title}
            style={{ display: 'block', marginTop: '0.25rem', fontSize: '1rem', padding: '0.25rem' }}
          />
        </label>
        <button type="submit" style={{ marginTop: '0.5rem' }}>Save title</button>
      </form>

      {/* Requirements */}
      <h2>Requirements</h2>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {remembrall.requirements.map((req, i) => (
          <li key={req.id} style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
            {/* Move up */}
            {i > 0 && (
              <form action={async () => {
                'use server'
                const ids = remembrall.requirements.map((r) => r.id)
                ;[ids[i - 1], ids[i]] = [ids[i], ids[i - 1]]
                await reorderRequirements(params.id, ids)
                redirect(`/remembrall/${params.id}/edit`)
              }}>
                <button type="submit">↑</button>
              </form>
            )}
            {/* Move down */}
            {i < remembrall.requirements.length - 1 && (
              <form action={async () => {
                'use server'
                const ids = remembrall.requirements.map((r) => r.id)
                ;[ids[i], ids[i + 1]] = [ids[i + 1], ids[i]]
                await reorderRequirements(params.id, ids)
                redirect(`/remembrall/${params.id}/edit`)
              }}>
                <button type="submit">↓</button>
              </form>
            )}
            <span style={{ flex: 1 }}>{req.text}</span>
            {/* Delete */}
            <form action={async () => {
              'use server'
              await deleteRequirement(req.id)
              redirect(`/remembrall/${params.id}/edit`)
            }}>
              <button type="submit" style={{ color: 'red' }}>✕</button>
            </form>
          </li>
        ))}
      </ul>

      {/* Add requirement */}
      <form action={handleAddRequirement} style={{ marginTop: '1rem' }}>
        <input
          name="text"
          placeholder="New requirement"
          style={{ fontSize: '1rem', padding: '0.25rem', marginRight: '0.5rem' }}
        />
        <button type="submit">Add</button>
      </form>

      {/* Delete remembrall */}
      <form action={handleDelete} style={{ marginTop: '2rem' }}>
        <button
          type="submit"
          style={{ color: 'red', background: 'none', border: '1px solid red', padding: '0.25rem 0.75rem', cursor: 'pointer' }}
          onClick={() => confirm('Delete this Remembrall?')}
        >
          Delete Remembrall
        </button>
      </form>
    </main>
  )
}
