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
  return (
    <AppLayout>
      <section className="space-y-6">
        <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-950">Service Windows</h1>

            <p className="mt-2 text-sm text-slate-600">
              Manage the attention windows assigned to QueueCare AI services.
            </p>
          </div>

          <button
            type="button"
            disabled
            className="inline-flex cursor-not-allowed items-center justify-center rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white opacity-60"
          >
            + New window
          </button>
        </div>

        <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
          <div className="overflow-hidden rounded-lg border border-slate-200">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Name
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Code
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Queue service
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                    Status
                  </th>
                </tr>
              </thead>

              <tbody className="divide-y divide-slate-200 bg-white">
                {serviceWindows.map((serviceWindow) => (
                  <tr key={serviceWindow.id}>
                    <td className="px-4 py-3 text-sm font-medium text-slate-900">
                      {serviceWindow.name}
                    </td>

                    <td className="px-4 py-3 text-sm text-slate-600">
                      <span className="rounded-md bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700">
                        {serviceWindow.code}
                      </span>
                    </td>

                    <td className="px-4 py-3 text-sm text-slate-600">
                      <span className="font-medium text-slate-900">
                        {serviceWindow.queue_service.name}
                      </span>
                      <span className="ml-2 rounded-md bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-600">
                        {serviceWindow.queue_service.code}
                      </span>
                    </td>

                    <td className="px-4 py-3 text-sm">
                      <span
                        className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${
                          serviceWindow.active
                            ? "bg-green-50 text-green-700"
                            : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {serviceWindow.active ? "Active" : "Inactive"}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <p className="mt-4 text-xs text-slate-500">
            Showing {serviceWindows.length} registered service windows.
          </p>
        </div>
      </section>
    </AppLayout>
  );
}
