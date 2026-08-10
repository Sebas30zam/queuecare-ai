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
  description: string | null;
  active: boolean;
  estimated_attention_minutes: number;
};

type QueueServicesIndexProps = {
  queue_services: QueueServiceRecord[];
};

export default function QueueServicesIndex({
  queue_services: queueServices,
}: QueueServicesIndexProps) {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [serviceToDelete, setServiceToDelete] = useState<QueueServiceRecord | null>(null);
  const [deleting, setDeleting] = useState(false);

  const activeServices = queueServices.filter((service) => service.active).length;

  const averageAttention =
    queueServices.length > 0
      ? (
          queueServices.reduce((total, service) => total + service.estimated_attention_minutes, 0) /
          queueServices.length
        ).toFixed(1)
      : "0";

  const filteredServices = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase();

    return queueServices.filter((service) => {
      const matchesSearch =
        normalizedSearch.length === 0 ||
        service.name.toLowerCase().includes(normalizedSearch) ||
        service.code.toLowerCase().includes(normalizedSearch);

      const matchesStatus =
        statusFilter === "all" ||
        (statusFilter === "active" && service.active) ||
        (statusFilter === "inactive" && !service.active);

      return matchesSearch && matchesStatus;
    });
  }, [queueServices, search, statusFilter]);

  function handleDelete() {
    if (!serviceToDelete) return;

    setDeleting(true);

    router.delete(`/queue_services/${serviceToDelete.id}`, {
      preserveScroll: true,
      onFinish: () => {
        setDeleting(false);
        setServiceToDelete(null);
      },
    });
  }

  return (
    <AppLayout>
      <section className="space-y-6">
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-6 px-6 py-6 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
                Service configuration
              </span>

              <h1 className="mt-3 text-3xl font-bold tracking-tight text-slate-950">
                Service Directory
              </h1>

              <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
                Configure the services available throughout QueueCare AI and their expected
                attention times.
              </p>
            </div>

            <Link
              href="/queue_services/new"
              className="inline-flex items-center justify-center rounded-xl bg-blue-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-blue-700"
            >
              <span className="mr-2 text-lg leading-none">+</span>
              New service
            </Link>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
          <AdminStatCard
            label="Services"
            value={queueServices.length}
            helper="Configured services"
          />

          <AdminStatCard
            label="Active services"
            value={activeServices}
            helper={`${queueServices.length - activeServices} inactive`}
          />

          <AdminStatCard
            label="Avg. attention"
            value={`${averageAttention} min`}
            helper="Expected service time"
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
                  placeholder="Search by service name or code..."
                  className="w-full rounded-xl border-slate-200 bg-slate-50 py-2.5 pl-9 pr-3 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                />
              </div>

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

          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-100">
              <thead className="bg-slate-50/80">
                <tr>
                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Service
                  </th>

                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Code
                  </th>

                  <th className="px-5 py-3.5 text-left text-xs font-bold uppercase tracking-[0.12em] text-slate-400">
                    Estimated attention
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
                {filteredServices.map((service) => (
                  <tr key={service.id} className="transition hover:bg-slate-50/70">
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-xs font-black text-blue-700">
                          {service.code.slice(0, 2)}
                        </div>

                        <div>
                          <p className="text-sm font-bold text-slate-900">{service.name}</p>

                          <p className="mt-0.5 text-xs text-slate-500">QueueCare AI service</p>
                        </div>
                      </div>
                    </td>

                    <td className="px-5 py-4">
                      <span className="inline-flex rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-black tracking-wide text-slate-700">
                        {service.code}
                      </span>
                    </td>

                    <td className="px-5 py-4">
                      <div>
                        <p className="text-sm font-bold text-slate-800">
                          {service.estimated_attention_minutes} min
                        </p>

                        <p className="mt-0.5 text-xs text-slate-400">Expected duration</p>
                      </div>
                    </td>

                    <td className="px-5 py-4">
                      <StatusBadge active={service.active} />
                    </td>

                    <td className="px-5 py-4">
                      <div className="flex justify-end gap-2">
                        <Link
                          href={`/queue_services/${service.id}/edit`}
                          className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-bold text-slate-600 transition hover:border-blue-200 hover:bg-blue-50 hover:text-blue-700"
                        >
                          Edit
                        </Link>

                        <button
                          type="button"
                          onClick={() => setServiceToDelete(service)}
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

            {filteredServices.length === 0 && (
              <div className="px-6 py-14 text-center">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-slate-100 text-xl text-slate-400">
                  ⌕
                </div>

                <h2 className="mt-4 text-sm font-bold text-slate-900">No services found</h2>

                <p className="mt-1 text-sm text-slate-500">
                  Try changing the current search or status filter.
                </p>
              </div>
            )}
          </div>

          <div className="flex flex-col gap-1 border-t border-slate-100 bg-slate-50/60 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs text-slate-500">
              Showing {filteredServices.length} of {queueServices.length} services.
            </p>

            <p className="text-xs text-slate-400">
              Service configuration affects ticket operations.
            </p>
          </div>
        </div>
      </section>

      <ConfirmDialog
        open={Boolean(serviceToDelete)}
        title="Delete service?"
        description={
          serviceToDelete
            ? `Are you sure you want to delete "${serviceToDelete.name}"? Services with related windows or operational records cannot be deleted.`
            : ""
        }
        confirmLabel="Delete service"
        processing={deleting}
        onCancel={() => setServiceToDelete(null)}
        onConfirm={handleDelete}
      />
    </AppLayout>
  );
}
