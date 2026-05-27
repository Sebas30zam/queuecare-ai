import type { ReactNode } from "react"

import Navbar from "../components/layout/Navbar"
import Sidebar from "../components/layout/Sidebar"

type AppLayoutProps = {
  children: ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-950">
      <div className="flex min-h-screen">
        <Sidebar />

        <div className="flex min-h-screen flex-1 flex-col">
          <Navbar />

          <main className="flex-1 px-6 py-6">
            {children}
          </main>
        </div>
      </div>
    </div>
  )
}
