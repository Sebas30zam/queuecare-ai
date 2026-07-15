import { router, usePage } from "@inertiajs/react";

type AuthUser = {
  id: number;
  name: string;
  email: string;
  role: string;
};

type SharedProps = {
  auth?: {
    user?: AuthUser | null;
  };
};

export default function Navbar() {
  const { auth } = usePage<SharedProps>().props;
  const { url } = usePage<SharedProps>();
  const user = auth?.user;
  const isDashboard = url.startsWith("/dashboard");

  function handleLogout() {
    router.delete("/logout");
  }

  return (
    <header className="border-b border-slate-200 bg-white px-6 py-3">
      <div className="flex items-center justify-between gap-4">
        {isDashboard ? (
          <div>
            <p className="text-sm font-bold text-slate-950">Operational Dashboard</p>
            <p className="text-[10px] text-slate-400">Real-time service monitoring</p>
          </div>
        ) : (
          <div className="w-full max-w-xs">
            <input
              type="text"
              placeholder="Search..."
              className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white"
            />
          </div>
        )}

        <div className="flex items-center gap-4">
          <div className="text-right">
            <p className="text-sm font-medium text-slate-900">{user?.name || "User"}</p>
            <p className="text-xs text-slate-500">{user?.role || "Development mode"}</p>
          </div>

          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-blue-600 text-sm font-semibold text-white">
            {user?.name
              ?.split(" ")
              .map((part) => part[0])
              .join("")
              .slice(0, 2)
              .toUpperCase() || "U"}
          </div>

          <button
            type="button"
            onClick={handleLogout}
            className="rounded-lg border border-red-100 px-3 py-2 text-sm font-medium text-red-500 transition hover:bg-red-50"
          >
            Sign out
          </button>
        </div>
      </div>
    </header>
  );
}
