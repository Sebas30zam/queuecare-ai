import AppLayout from "../../layouts/AppLayout"

export default function Home() {
  return (
    <AppLayout>
      <section className="mx-auto flex min-h-screen max-w-5xl flex-col justify-center px-6 py-16">
        <p className="mb-4 text-sm font-semibold uppercase tracking-wide text-cyan-400">
          QueueCare AI
        </p>

        <h1 className="max-w-3xl text-4xl font-bold tracking-tight sm:text-6xl">
          Intelligent queue management for modern service operations.
        </h1>

        <p className="mt-6 max-w-2xl text-lg text-slate-300">
          A Rails monolith built with Inertia, React, TypeScript,
          TailwindCSS and PostgreSQL.
        </p>
      </section>
    </AppLayout>
  )
}