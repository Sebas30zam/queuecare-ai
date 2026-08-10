import { useMemo, useState } from "react";

import { Link, router } from "@inertiajs/react";

import AdminStatCard from "../../components/admin/AdminStatCard";
import ConfirmDialog from "../../components/admin/ConfirmDialog";
import RoleBadge from "../../components/admin/RoleBadge";
import StatusBadge from "../../components/admin/StatusBadge";
import AppLayout from "../../layouts/AppLayout";

type UserRecord = {
  id: number;
  name: string;
  email: string;
  role: string;
  active: boolean;
  can_delete: boolean;
};

type UsersIndexProps = {
  users: UserRecord[];
  current_user_id: number;
};

function initialsFor(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .map((part) => part[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

export default function UsersIndex({ users, current_user_id: currentUserId }: UsersIndexProps) {
  const [search, setSearch] = useState("");
  const [roleFilter, setRoleFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");
  const [userToDelete, setUserToDelete] = useState<UserRecord | null>(null);
  const [deleting, setDeleting] = useState(false);

  const filteredUsers = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();

    return users.filter((user) => {
      const matchesSearch =
        normalizedSearch.length === 0 ||
        user.name.toLowerCase().includes(normalizedSearch) ||
        user.email.toLowerCase().includes(normalizedSearch);

      const matchesRole = roleFilter === "all" || user.role === roleFilter;

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "active" && user.active) ||
        (statusFilter === "inactive" && !user.active);

      return matchesSearch && matchesRole && matchesStatus;
    });
  }, [roleFilter, search, statusFilter, users]);

  const activeUsers = users.filter((user) => user.active).length;
  const supervisorCount = users.filter((user) => user.role === "supervisor").length;

  const visibleRoles = Array.from(new Set(users.map((user) => user.role))).sort();

  function handleDelete() {
    if (!userToDelete) return;

    setDeleting(true);

    router.delete(`/users/${userToDelete.id}`, {
      preserveScroll: true,
      onFinish: () => {
        setDeleting(false);
        setUserToDelete(null);
      },
    });
  }

  return (
    <AppLayout>
      <section className="space-y-6">
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-6 px-6 py-6 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <div className="mb-2 flex items-center gap-2">
                <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
                  Administration
                </span>
              </div>

              <h1 className="text-3xl font-bold tracking-tight text-slate-950">Staff Directory</h1>

              <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
                Manage staff accounts, access roles, and operational status for QueueCare AI.
              </p>
            </div>

            <Link
              href="/users/new"
              className="inline-flex items-center justify-center rounded-xl bg-blue-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-blue-700"
            >
              <span className="mr-2 text-lg leading-none">+</span>
              New user
            </Link>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
          <AdminStatCard
            label="Visible staff"
            value={users.length}
            helper="Accounts you can manage"
          />

          <AdminStatCard
            label="Active accounts"
            value={activeUsers}
            helper={`${users.length - activeUsers} inactive`}
          />

          <AdminStatCard
            label="Supervisors"
            value={supervisorCount}
            helper="Operational oversight"
          />
        </div>

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 px-5 py-5">
            <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
              <div className="relative w-full lg:max-w-md">
                <span className="pointer-events-none absolute inset-y-0 left-3 flex items-center text-slate-400">
                  ⌕
                </span>

                <input
                  type="search"
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder="Search by name or email..."
                  className="w-full rounded-xl border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm text-slate-700 shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                />
              </div>

              <div className="flex flex-col gap-2 sm:flex-row">
                <select
                  value={roleFilter}
                  onChange={(event) => setRoleFilter(event.target.value)}
                  className="rounded-xl border-slate-200 bg-white py-2.5 pl-3 pr-9 text-sm font-medium text-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="all">All roles</option>

                  {visibleRoles.map((role) => (
                    <option key={role} value={role}>
                      {role.charAt(0).toUpperCase() + role.slice(1)}
                    </option>
                  ))}
                </select>

                <select
                  value={statusFilter}
                  onChange={(event) => setStatusFilter(event.target.value)}
                  className="rounded-xl border-slate-200 bg-white py-2.5 pl-3 pr-9 text-sm font-medium text-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="all">Any status</option>
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>
              </div>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-100">
              <thead className="bg-slate-50/80">
                <tr>
                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Staff member
                  </th>

                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Role
                  </th>

                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Status
                  </th>

                  <th className="px-5 py-3.5 text-right text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Actions
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-100 bg-white">
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="transition hover:bg-slate-50/70">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-slate-100 text-xs font-bold text-slate-700">
                          {initialsFor(user.name)}
                        </div>

                        <div className="min-w-0">
                          <div className="flex items-center gap-2">
                            <p className="truncate text-sm font-bold text-slate-900">{user.name}</p>

                            {user.id === currentUserId && (
                              <span className="rounded-md bg-blue-50 px-1.5 py-0.5 text-[10px] font-bold uppercase tracking-wide text-blue-600">
                                You
                              </span>
                            )}
                          </div>

                          <p className="mt-0.5 truncate text-xs text-slate-500">{user.email}</p>
                        </div>
                      </div>
                    </td>

                    <td className="px-5 py-4">
                      <RoleBadge role={user.role} />
                    </td>

                    <td className="px-5 py-4">
                      <StatusBadge active={user.active} />
                    </td>

                    <td className="px-5 py-4">
                      <div className="flex justify-end gap-2">
                        <Link
                          href={`/users/${user.id}/edit`}
                          className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-700"
                        >
                          Edit
                        </Link>

                        {user.can_delete ? (
                          <button
                            type="button"
                            onClick={() => setUserToDelete(user)}
                            className="rounded-lg border border-red-100 bg-white px-3 py-2 text-xs font-bold text-red-600 transition hover:bg-red-50"
                          >
                            Delete
                          </button>
                        ) : (
                          <span className="inline-flex items-center rounded-lg bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-400">
                            Current account
                          </span>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {filteredUsers.length === 0 && (
              <div className="px-6 py-14 text-center">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-xl text-slate-400">
                  ⌕
                </div>

                <h2 className="mt-4 text-sm font-bold text-slate-900">No staff members found</h2>

                <p className="mt-1 text-sm text-slate-500">
                  Try changing the current search or filters.
                </p>
              </div>
            )}
          </div>

          <div className="flex flex-col gap-1 border-t border-slate-100 bg-slate-50/60 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs text-slate-500">
              Showing {filteredUsers.length} of {users.length} staff accounts.
            </p>

            <p className="text-xs text-slate-400">
              Changes to roles and status affect system access.
            </p>
          </div>
        </div>
      </section>

      <ConfirmDialog
        open={Boolean(userToDelete)}
        title="Delete user?"
        description={
          userToDelete
            ? `Are you sure you want to delete "${userToDelete.name}"? This action cannot be undone.`
            : ""
        }
        confirmLabel="Delete user"
        processing={deleting}
        onCancel={() => setUserToDelete(null)}
        onConfirm={handleDelete}
      />
    </AppLayout>
  );
}
