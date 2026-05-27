const navigationItems = [
  { label: "Home", href: "/" },
  { label: "Users", href: "#", disabled: true },
  { label: "Services", href: "#", disabled: true },
  { label: "Service Windows", href: "#", disabled: true },
  { label: "Tickets", href: "#", disabled: true },
]

export default function Sidebar() {
  return (
    <aside className="hidden min-h-screen w-64 border-r border-slate-200 bg-white px-5 py-5 lg:flex lg:flex-col">
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
        {navigationItems.map((item) => (
          <a
            key={item.label}
            href={item.href}
            aria-disabled={item.disabled}
            className={`block rounded-lg px-3 py-2 text-sm font-medium transition ${
              item.href === "/"
                ? "bg-blue-600 text-white"
                : "text-slate-600 hover:bg-slate-100 hover:text-slate-900"
            } ${
              item.disabled ? "cursor-not-allowed opacity-60" : ""
            }`}
          >
            {item.label}
          </a>
        ))}
      </nav>

      <div className="mt-auto border-t border-slate-200 pt-4">
        <p className="text-xs text-slate-400">
          QueueCare AI MVP
        </p>
      </div>
    </aside>
  )
}
