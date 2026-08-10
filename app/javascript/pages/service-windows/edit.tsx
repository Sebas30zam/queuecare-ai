import { FormEvent } from "react";

import { Link, useForm } from "@inertiajs/react";

import FormSection from "../../components/admin/FormSection";
import StatusBadge from "../../components/admin/StatusBadge";
import AppLayout from "../../layouts/AppLayout";

type QueueServiceRecord = {
  id: number;
  name: string;
  code: string;
  active: boolean;
};

type ServiceWindowRecord = {
  id: number;
  name: string;
  code: string;
  active: boolean;
  queue_service_id: number;
  queue_service: {
    id: number;
    name: string;
    code: string;
  };
};

type ServiceWindowsEditProps = {
  service_window: ServiceWindowRecord;
  queue_services: QueueServiceRecord[];
};

type ServiceWindowFormData = {
  name: string;
  code: string;
  queue_service_id: string;
  active: boolean;
};

export default function ServiceWindowsEdit({
  service_window: serviceWindow,
  queue_services: queueServices,
}: ServiceWindowsEditProps) {
  const { data, setData, patch, processing, errors, transform } = useForm<ServiceWindowFormData>({
    name: serviceWindow.name,
    code: serviceWindow.code,
    queue_service_id: String(serviceWindow.queue_service_id),
    active: serviceWindow.active,
  });

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    transform((formData) => ({
      service_window: formData,
    }));

    patch(`/service_windows/${serviceWindow.id}`);
  }

  return (
    <AppLayout>
      <section className="mx-auto max-w-4xl space-y-6">
        <Link
          href="/service_windows"
          className="inline-flex items-center gap-2 text-sm font-semibold text-slate-500 transition hover:text-blue-600"
        >
          ← Back to Service Windows
        </Link>

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 bg-gradient-to-r from-slate-50 via-white to-white px-7 py-7">
            <div className="flex flex-col gap-5 sm:flex-row sm:items-center">
              <div className="flex h-16 w-16 shrink-0 items-center justify-center rounded-2xl bg-blue-600 text-lg font-black text-white shadow-sm">
                {serviceWindow.code}
              </div>

              <div>
                <span className="text-xs font-bold uppercase tracking-[0.16em] text-slate-400">
                  Editing service window
                </span>

                <h1 className="mt-1 text-3xl font-bold tracking-tight text-slate-950">
                  {serviceWindow.name}
                </h1>

                <div className="mt-3 flex flex-wrap items-center gap-3">
                  <span className="rounded-lg bg-slate-100 px-2.5 py-1 text-xs font-black text-slate-700">
                    {serviceWindow.code}
                  </span>

                  <StatusBadge active={serviceWindow.active} />

                  <span className="text-xs font-medium text-slate-400">
                    {serviceWindow.queue_service.name}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-7 p-7">
            <FormSection
              eyebrow="Window"
              title="Window information"
              description="Update how this service point is identified throughout QueueCare AI."
            >
              <div className="grid gap-5 md:grid-cols-2">
                <div>
                  <label htmlFor="name" className="mb-2 block text-sm font-bold text-slate-700">
                    Window name
                  </label>

                  <input
                    id="name"
                    type="text"
                    required
                    value={data.name}
                    onChange={(event) => setData("name", event.target.value)}
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.name && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.name}</p>
                  )}
                </div>

                <div>
                  <label htmlFor="code" className="mb-2 block text-sm font-bold text-slate-700">
                    Window code
                  </label>

                  <input
                    id="code"
                    type="text"
                    required
                    value={data.code}
                    onChange={(event) => setData("code", event.target.value)}
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm uppercase shadow-sm focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.code && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.code}</p>
                  )}
                </div>
              </div>
            </FormSection>

            <FormSection
              eyebrow="Assignment"
              title="Service assignment"
              description="Reassign this window if its operational responsibility changes."
            >
              <div>
                <label
                  htmlFor="queue_service_id"
                  className="mb-2 block text-sm font-bold text-slate-700"
                >
                  Queue service
                </label>

                <select
                  id="queue_service_id"
                  required
                  value={data.queue_service_id}
                  onChange={(event) => setData("queue_service_id", event.target.value)}
                  className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                >
                  {queueServices.map((service) => (
                    <option key={service.id} value={service.id}>
                      {service.name} ({service.code}){service.active ? "" : " — Inactive"}
                    </option>
                  ))}
                </select>

                {errors.queue_service_id && (
                  <p className="mt-2 text-xs font-medium text-red-600">{errors.queue_service_id}</p>
                )}
              </div>
            </FormSection>

            <FormSection
              eyebrow="Operations"
              title="Window status"
              description="Disable this window when it should no longer be available to agents."
            >
              <label className="flex cursor-pointer items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-4 py-3.5 transition hover:bg-white">
                <div>
                  <p className="text-sm font-bold text-slate-800">Active window</p>

                  <p className="mt-0.5 text-xs text-slate-500">
                    Active windows remain available for agent queue operations.
                  </p>
                </div>

                <input
                  type="checkbox"
                  checked={data.active}
                  onChange={(event) => setData("active", event.target.checked)}
                  className="h-5 w-5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                />
              </label>
            </FormSection>

            <div className="flex flex-col-reverse gap-3 border-t border-slate-100 pt-6 sm:flex-row sm:justify-end">
              <Link
                href="/service_windows"
                className="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold text-slate-600 transition hover:bg-slate-50"
              >
                Cancel
              </Link>

              <button
                type="submit"
                disabled={processing}
                className="inline-flex items-center justify-center rounded-xl bg-blue-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {processing ? "Saving changes..." : "Save changes"}
              </button>
            </div>
          </form>
        </div>
      </section>
    </AppLayout>
  );
}
