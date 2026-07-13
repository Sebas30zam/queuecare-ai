import { usePage } from "@inertiajs/react"

type AuthUser = {
  id: number
  name: string
  email: string
  role: string
}

type SharedProps = {
  auth?: {
    user?: AuthUser | null
  }
}

type NavigationItem = {
  label: string
  href: string
  disabled?: boolean
  allowedRoles?: string[]
}

const navigationItems: NavigationItem[] = [
  { label: "Home", href: "/" },
  {
    label: "Dashboard",
    href: "/dashboard",
    allowedRoles: ["admin", "supervisor"],
  },
  { label: "Users", href: "/users", allowedRoles: ["admin", "supervisor"] },
  { label: "Queue Services", href: "/queue_services", allowedRoles: ["admin", "supervisor"] },
  { label: "Service Windows", href: "/service_windows", allowedRoles: ["admin", "supervisor"] },
  {
    label: "Assisted Intake",
    href: "/tickets/reception",
    allowedRoles: ["admin", "receptionist"],
  },
  {
    label: "Agent Queue",
    href: "/agent-queue",
    allowedRoles: ["agent", "admin"],
  },
]

export default function Sidebar() {
  const { url, props } = usePage<SharedProps>()
  const userRole = props.auth?.user?.role

  const visibleNavigationItems = navigationItems.filter((item) => {
    if (!item.allowedRoles) return true

    return Boolean(userRole && item.allowedRoles.includes(userRole))
  })

  return (
    <aside className="hidden min-h-screen w-64 shrink-0 border-r border-slate-200 bg-white px-5 py-5 lg:flex lg:flex-col">
      <div className="mb-8 flex items-center gap-2">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-600 text-sm font-bold text-white">
          Q
        </div>

        <div>
          <p className="text-sm font-bold text-blue-600">
            QueueCare AI
          </p>
          <p className="text-xs text-slate-500">
            Operations system
          </p>
        </div>
      </div>

      <nav className="space-y-1">
        {visibleNavigationItems.map((item) => {
          const isActive = item.href === "/" ? url === "/" : url.startsWith(item.href)

          return (
            <a
              key={item.label}
              href={item.href}
              aria-current={isActive ? "page" : undefined}
              aria-disabled={item.disabled}
              onClick={(event) => {
                if (item.disabled) event.preventDefault()
              }}
              className={`block rounded-lg px-3 py-2 text-sm font-medium transition ${
                isActive
                  ? "bg-blue-600 text-white"
                  : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
              } ${
                item.disabled ? "cursor-not-allowed opacity-60" : ""
              }`}
            >
              {item.label}
            </a>
          )
        })}
      </nav>

      <div className="mt-auto border-t border-slate-200 pt-4">
        <p className="text-xs text-slate-400">
          QueueCare AI MVP
        </p>
      </div>
    </aside>
  )
}
