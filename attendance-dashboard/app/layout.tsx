import type { Metadata } from 'next'
import { AuthProvider } from './context/AuthContext'
import AppShell from './components/AppShell'
import './globals.css'

export const metadata: Metadata = {
  title: 'AttendanceAI',
  description: 'Face Recognition Attendance System',
  manifest: '/manifest.json',
  icons: {
    icon: '/icon-192.png',
    apple: '/icon-192.png',
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="bg-gray-50">
        <AuthProvider>
          <AppShell>{children}</AppShell>
        </AuthProvider>
      </body>
    </html>
  )
}
