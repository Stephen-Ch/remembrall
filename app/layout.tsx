import type { Metadata } from 'next'
import './globals.css'
import ServiceWorkerRegistrar from '@/app/components/ServiceWorkerRegistrar'
import OfflineIndicator from '@/app/components/OfflineIndicator'

export const metadata: Metadata = {
  title: 'Remembrall',
  description: 'Shareable checklists',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>
        {children}
        <ServiceWorkerRegistrar />
        <OfflineIndicator />
      </body>
    </html>
  )
}
