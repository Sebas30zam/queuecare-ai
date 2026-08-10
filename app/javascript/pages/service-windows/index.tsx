import { useMemo, useState } from "react";

import { Link, router } from "@inertiajs/react";

import AdminStatCard from "../../components/admin/AdminStatCard";
import ConfirmDialog from "../../components/admin/ConfirmDialog";
import StatusBadge from "../../components/admin/StatusBadge";
import AppLayout from "../../layouts/AppLayout";

type QueueServiceRecord = {
  id: number;
  name: string;
  code: string;
};

type ServiceWindowRecord = {
  id: number;
  name: string;
  code: string;
  active: boolean;
  queue_service: QueueServiceRecord;
};

type ServiceWindowsIndexProps = {
  service_windows: ServiceWindowRecord[];
};

export default function ServiceWindowsIndex({
  service_windows: serviceWindows,
}: ServiceWindowsIndexProps) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [serviceFilter, setServiceFilter] = useState("all");
  const [windowToDelete, setWindowToDelete] = useState<ServiceWindowRecord | null>(null);
  const [deleting, setDeleting] = useState(false);

  const activeWindows = serviceWindows.filter((serviceWindow) => serviceWindow.active).length;

  const assignedServices = new Set(
    serviceWindows.map((serviceWindow) => serviceWindow.queue_service.id),
  ).size;

  const availableServices = Array.from(
    new Map(
      serviceWindows.map((serviceWindow) => [
        serviceWindow.queue_service.id,
        serviceWindow.queue_service,
      ]),
    ).values(),
  ).sort((a, b) => a.name.localeCompare(b.name));

  const filteredWindows = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();

    return serviceWindows.filter((serviceWindow) => {
      const matchesSearch =
        normalizedSearch.length === 0 ||
        serviceWindow.name.toLowerCase().includes(normalizedSearch) ||
        serviceWindow.code.toLowerCase().includes(normalizedSearch) ||
        serviceWindow.queue_service.name.toLowerCase().includes(normalizedSearch);

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "active" && serviceWindow.active) ||
        (statusFilter === "inactive" && !serviceWindow.active);

      const matchesService =
        serviceFilter === "all" || String(serviceWindow.queue_service.id) === serviceFilter;

      return matchesSearch && matchesStatus && matchesService;
    });
  }, [search, serviceFilter, serviceWindows, statusFilter]);

  function handleDelete() {
    if (!windowToDelete) return;

    setDeleting(true);

    router.delete(`/service_windows/${windowToDelete.id}`, {
      preserveScroll: true,
      onFinish: () => {
        setDeleting(false);
        setWindowToDelete(null);
      },
    });
  }

  return (
    <AppLayout>
      <section className="space-y-6">
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-3 px-5 py-4 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
                Window configuration
              </span>

              <h1 className="mt-2 text-2xl font-bold tracking-tight text-slate-950">
                Service Windows
              </h1>

              <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
                Manage service points and assign each window to the QueueCare AI service it handles.
              </p>
            </div>

            <Link
              href="/service_windows/new"
              className="inline-flex items-center justify-center rounded-xl bg-blue-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-blue-700"
            >
              <span className="mr-2 text-lg leading-none">+</span>
              New window
            </Link>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
          <AdminStatCard
            label="Service windows"
            value={serviceWindows.length}
            helper="Configured windows"
          />

          <AdminStatCard
            label="Active windows"
            value={activeWindows}
            helper={`${serviceWindows.length - activeWindows} inactive`}
          />

          <AdminStatCard
            label="Assigned services"
            value={assignedServices}
            helper="Services with windows"
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
                  placeholder="Search by window, code, or service..."
                  className="w-full rounded-xl border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                />
              </div>

              <div className="flex flex-col gap-2 sm:flex-row">
                <select
                  value={serviceFilter}
                  onChange={(event) => setServiceFilter(event.target.value)}
                  className="rounded-xl border-slate-200 bg-white py-2.5 pl-3 pr-9 text-sm font-medium text-slate-600 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="all">All services</option>

                  {availableServices.map((service) => (
                    <option key={service.id} value={service.id}>
                      {service.name}
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
                    Service window
                  </th>

                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Code
                  </th>

                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Assigned service
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
                {filteredWindows.map((serviceWindow) => (
                  <tr key={serviceWindow.id} className="transition hover:bg-slate-50/70">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-xs font-black text-blue-700">
                          {serviceWindow.code}
                        </div>

                        <div>
                          <p className="text-sm font-bold text-slate-900">{serviceWindow.name}</p>

                          <p className="mt-0.5 text-xs text-slate-500">Attention point</p>
                        </div>
                      </div>
                    </td>

                    <td className="px-5 py-4">
                      <span className="inline-flex rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-black tracking-wide text-slate-700">
                        {serviceWindow.code}
                      </span>
                    </td>

                    <td className="px-5 py-4">
                      <div>
                        <p className="text-sm font-bold text-slate-800">
                          {serviceWindow.queue_service.name}
                        </p>

                        <p className="mt-0.5 text-xs font-semibold text-slate-400">
                          {serviceWindow.queue_service.code}
                        </p>
                      </div>
                    </td>

                    <td className="px-5 py-4">
                      <StatusBadge active={serviceWindow.active} />
                    </td>

                    <td className="px-5 py-4">
                      <div className="flex justify-end gap-2">
                        <Link
                          href={`/service_windows/${serviceWindow.id}/edit`}
                          className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-700"
                        >
                          Edit
                        </Link>

                        <button
                          type="button"
                          onClick={() => setWindowToDelete(serviceWindow)}
                          className="rounded-lg border border-red-100 bg-white px-3 py-2 text-xs font-bold text-red-600 transition hover:bg-red-50"
                        >
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {filteredWindows.length === 0 && (
              <div className="px-6 py-14 text-center">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-xl text-slate-400">
                  ⌕
                </div>

                <h2 className="mt-4 text-sm font-bold text-slate-900">No service windows found</h2>

                <p className="mt-1 text-sm text-slate-500">
                  Try changing the current search or filters.
                </p>
              </div>
            )}
          </div>

          <div className="flex flex-col gap-1 border-t border-slate-100 bg-slate-50/60 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs text-slate-500">
              Showing {filteredWindows.length} of {serviceWindows.length} service windows.
            </p>

            <p className="text-xs text-slate-400">
              Window assignments affect agent queue operations.
            </p>
          </div>
        </div>
      </section>

      <ConfirmDialog
        open={Boolean(windowToDelete)}
        title="Delete service window?"
        description={
          windowToDelete
            ? `Are you sure you want to delete "${windowToDelete.name}"? Windows with related operational records cannot be deleted.`
            : ""
        }
        confirmLabel="Delete window"
        processing={deleting}
        onCancel={() => setWindowToDelete(null)}
        onConfirm={handleDelete}
      />
    </AppLayout>
  );
}
