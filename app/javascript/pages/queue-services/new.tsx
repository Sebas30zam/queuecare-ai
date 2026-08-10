import { FormEvent } from "react";

import { Link, useForm } from "@inertiajs/react";

import FormSection from "../../components/admin/FormSection";
import AppLayout from "../../layouts/AppLayout";

type QueueServiceFormData = {
  name: string;
  code: string;
  estimated_attention_minutes: string;
  active: boolean;
};

export default function QueueServicesNew() {
  const { data, setData, post, processing, errors, transform } = useForm<QueueServiceFormData>({
    name: "",
    code: "",
    estimated_attention_minutes: "",
    active: true,
  });

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    transform((formData) => ({
      queue_service: formData,
    }));

    post("/queue_services");
  }

  return (
    <AppLayout>
      <section className="mx-auto max-w-4xl space-y-6">
        <Link
          href="/queue_services"
          className="inline-flex items-center gap-2 text-sm font-semibold text-slate-500 transition hover:text-blue-600"
        >
          ← Back to Service Directory
        </Link>

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="border-b border-slate-100 bg-gradient-to-r from-blue-50/80 via-white to-white px-7 py-7">
            <span className="rounded-full bg-blue-100 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
              Service configuration
            </span>

            <h1 className="mt-4 text-3xl font-bold tracking-tight text-slate-950">
              Create service
            </h1>

            <p className="mt-2 max-w-2xl text-sm leading-6 text-slate-600">
              Add a new service and define its expected attention time for QueueCare AI operations.
            </p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-7 p-7">
            <FormSection
              eyebrow="Service"
              title="Service information"
              description="Define how this service will be identified throughout the queue system."
            >
              <div className="grid gap-5 md:grid-cols-2">
                <div>
                  <label htmlFor="name" className="mb-2 block text-sm font-bold text-slate-700">
                    Service name
                  </label>

                  <input
                    id="name"
                    type="text"
                    required
                    value={data.name}
                    onChange={(event) => setData("name", event.target.value)}
                    placeholder="e.g. Student Support"
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.name && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.name}</p>
                  )}
                </div>

                <div>
                  <label htmlFor="code" className="mb-2 block text-sm font-bold text-slate-700">
                    Service code
                  </label>

                  <input
                    id="code"
                    type="text"
                    required
                    value={data.code}
                    onChange={(event) => setData("code", event.target.value)}
                    placeholder="e.g. STS"
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm uppercase shadow-sm transition placeholder:text-slate-400 focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  />

                  {errors.code && (
                    <p className="mt-2 text-xs font-medium text-red-600">{errors.code}</p>
                  )}
                </div>
              </div>
            </FormSection>

            <FormSection
              eyebrow="Operations"
              title="Attention configuration"
              description="Set the expected service duration and whether this service is currently available."
            >
              <div className="grid gap-5 md:grid-cols-2">
                <div>
                  <label
                    htmlFor="estimated_attention_minutes"
                    className="mb-2 block text-sm font-bold text-slate-700"
                  >
                    Estimated attention time
                  </label>

                  <div className="relative">
                    <input
                      id="estimated_attention_minutes"
                      type="number"
                      min="1"
                      required
                      value={data.estimated_attention_minutes}
                      onChange={(event) =>
                        setData("estimated_attention_minutes", event.target.value)
                      }
                      placeholder="15"
                      className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 pr-20 text-sm shadow-sm transition focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                    />

                    <span className="pointer-events-none absolute inset-y-0 right-4 flex items-center text-xs font-bold text-slate-400">
                      minutes
                    </span>
                  </div>

                  {errors.estimated_attention_minutes && (
                    <p className="mt-2 text-xs font-medium text-red-600">
                      {errors.estimated_attention_minutes}
                    </p>
                  )}
                </div>

                <div>
                  <p className="mb-2 text-sm font-bold text-slate-700">Service status</p>

                  <label className="flex cursor-pointer items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-4 py-3.5 transition hover:bg-white">
                    <div>
                      <p className="text-sm font-bold text-slate-800">Active service</p>

                      <p className="mt-0.5 text-xs text-slate-500">
                        Active services can receive new tickets.
                      </p>
                    </div>

                    <input
                      type="checkbox"
                      checked={data.active}
                      onChange={(event) => setData("active", event.target.checked)}
                      className="h-5 w-5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                    />
                  </label>
                </div>
              </div>
            </FormSection>

            <div className="flex flex-col-reverse gap-3 border-t border-slate-100 pt-6 sm:flex-row sm:justify-end">
              <Link
                href="/queue_services"
                className="inline-flex items-center justify-center rounded-xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold text-slate-600 transition hover:bg-slate-50"
              >
                Cancel
              </Link>

              <button
                type="submit"
                disabled={processing}
                className="inline-flex items-center justify-center rounded-xl bg-blue-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {processing ? "Creating service..." : "Create service"}
              </button>
            </div>
          </form>
        </div>
      </section>
    </AppLayout>
  );
}
