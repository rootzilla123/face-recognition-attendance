import type { Metadata } from 'next'
import { Outfit } from 'next/font/google'
import { AuthProvider } from './context/AuthContext'
import AppShell from './components/AppShell'
import './globals.css'

const outfit = Outfit({ 
  subsets: ['latin'],
  variable: '--font-outfit',
})

export const metadata: Metadata = {
  title: 'ShadomFacePro',
  description: 'Next-Gen Face Recognition Attendance System',
  manifest: '/manifest.json',
  icons: {
    icon: '/icon.svg',
    apple: '/icon.svg',
  },
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${outfit.variable} font-sans`}>
      <body className="bg-gray-50 antialiased selection:bg-blue-200">
        <AuthProvider>
          <AppShell>{children}</AppShell>
        </AuthProvider>
      </body>
    </html>
  )
}
