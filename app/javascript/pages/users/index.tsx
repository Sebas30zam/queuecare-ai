import AppLayout from "../../layouts/AppLayout"

type UserRecord = {
  id: number
  name: string
  email: string
  role: string
  active: boolean
}

type UsersIndexProps = {
  users: UserRecord[]
}

export default function UsersIndex({ users }: UsersIndexProps) {
  return (
    <AppLayout>
      <section className="space-y-6">
        <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-950">
              Directorio de Personal
            </h1>

            <p className="mt-2 text-sm text-slate-600">
              Administre los accesos, roles y estado operativo del personal de QueueCare AI.
            </p>
          </div>

          <button
            type="button"
            disabled
            className="inline-flex cursor-not-allowed items-center justify-center rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white opacity-60"
          >
            + Nuevo usuario
          </button>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <input
              type="text"
              placeholder="Buscar por nombre o correo..."
              disabled
              className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-500 outline-none sm:max-w-sm"
            />

            <div className="flex gap-2">
              <button
                type="button"
                disabled
                className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-500"
              >
                Todos los roles
              </button>

              <button
                type="button"
                disabled
                className="rounded-lg border border-slate-200 px-3 py-2 text-sm text-slate-500"
              >
                Cualquier estado
              </button>
            </div>
          </div>

          <div className="overflow-hidden rounded-lg border border-slate-200">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Nombre
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Correo institucional
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Rol
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Estado
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200 bg-white">
                {users.map((user) => (
                  <tr key={user.id}>
                    <td className="px-4 py-3 text-sm font-medium text-slate-900">
                      {user.name}
                    </td>

                    <td className="px-4 py-3 text-sm text-slate-600">
                      {user.email}
                    </td>

                    <td className="px-4 py-3 text-sm text-slate-600">
                      {user.role}
                    </td>

                    <td className="px-4 py-3 text-sm">
                      <span
                        className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${
                          user.active
                            ? "bg-green-50 text-green-700"
                            : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {user.active ? "Activo" : "Inactivo"}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <p className="mt-4 text-xs text-slate-500">
            Mostrando {users.length} usuarios registrados.
          </p>
        </div>
      </section>
    </AppLayout>
  )
}
