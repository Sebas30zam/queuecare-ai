import { router, useForm, usePage } from "@inertiajs/react";
import type { FormEvent } from "react";
import { useMemo, useState } from "react";

import AppLayout from "../../layouts/AppLayout";
import type { FlashData } from "../../types";

type QueueServiceRecord = {
  id: number;
  name: string;
  code: string;
};

type RecentTicketRecord = {
  id: number;
  ticket_number: string;
  service: QueueServiceRecord;
  priority: string;
  assistance_type: string | null;
  intake_source: string;
  status: string;
  created_at: string;
};

type TicketReceptionProps = {
  queue_services: QueueServiceRecord[];
  assistance_types: string[];
  recent_tickets: RecentTicketRecord[];
};

type TicketFormData = {
  queue_service_id: string;
  assistance_type: string;
};

type SharedPageProps = {
  flash?: FlashData;
};

const assistanceLabels: Record<string, string> = {
  disability: "Disability",
  senior: "Senior adult",
  pregnancy: "Pregnancy",
  appointment: "Scheduled appointment",
};

function formatCreatedAt(createdAt: string) {
  return new Date(createdAt).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatStatus(status: string) {
  return status
    .split("_")
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(" ");
}

function statusClasses(status: string) {
  if (status === "pending") {
    return "bg-amber-50 text-amber-700 ring-amber-600/10";
  }

  if (status === "called") {
    return "bg-blue-50 text-blue-700 ring-blue-600/10";
  }

  if (status === "in_attention") {
    return "bg-cyan-50 text-cyan-700 ring-cyan-600/10";
  }

  if (status === "attended") {
    return "bg-emerald-50 text-emerald-700 ring-emerald-600/10";
  }

  return "bg-slate-100 text-slate-600 ring-slate-500/10";
}

export default function TicketReception({
  queue_services: queueServices,
  assistance_types: assistanceTypes,
  recent_tickets: recentTickets,
}: TicketReceptionProps) {
  const { props } = usePage<SharedPageProps>();
  const flash = props.flash;
  const [requestAssistance, setRequestAssistance] = useState(false);

  const form = useForm<TicketFormData>({
    queue_service_id: "",
    assistance_type: "",
  });

  const selectedService = useMemo(
    () =>
      queueServices.find((service) => String(service.id) === form.data.queue_service_id) ?? null,
    [form.data.queue_service_id, queueServices],
  );

  const canSubmit =
    form.data.queue_service_id !== "" &&
    (!requestAssistance || form.data.assistance_type !== "") &&
    !form.processing;

  const handleAssistanceChange = (checked: boolean) => {
    setRequestAssistance(checked);

    if (!checked) {
      form.setData("assistance_type", "");
    }
  };

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    form.transform((formData) => ({
      ticket: {
        queue_service_id: formData.queue_service_id,
        assistance_type: requestAssistance ? formData.assistance_type : "",
      },
    }));

    form.post("/tickets", {
      preserveScroll: true,
      onSuccess: () => {
        form.reset();
        setRequestAssistance(false);
      },
    });
  };

  const handleCancelTicket = (ticket: RecentTicketRecord) => {
    router.patch(
      `/tickets/${ticket.id}/cancel`,
      {},
      {
        preserveScroll: true,
      },
    );
  };

  return (
    <AppLayout>
      <section className="flex h-[calc(100vh-8rem)] min-h-0 flex-col gap-3 overflow-hidden">
        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex flex-col gap-2 px-5 py-3 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
                Ticket operations
              </span>

              <h1 className="mt-1.5 text-2xl font-bold tracking-tight text-slate-950">
                Assisted Ticket Intake
              </h1>

              <p className="mt-1 max-w-2xl text-sm text-slate-600">
                Create a ticket for customers who need staff assistance during the intake process.
              </p>
            </div>

            <div className="rounded-xl border border-blue-100 bg-blue-50 px-4 py-1.5">
              <p className="text-xs font-bold uppercase tracking-[0.14em] text-blue-500">
                Intake mode
              </p>

              <p className="mt-1 text-sm font-bold text-blue-800">Staff assisted</p>
            </div>
          </div>
        </div>

        {flash?.notice && (
          <div className="rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-medium text-emerald-700">
            {flash.notice}
          </div>
        )}

        {flash?.alert && (
          <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {flash.alert}
          </div>
        )}

        <div className="grid min-h-0 flex-1 gap-4 xl:grid-cols-[minmax(0,1fr)_330px]">
          <form
            onSubmit={submit}
            className="flex min-h-0 flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm"
          >
            <div className="border-b border-slate-100 bg-gradient-to-r from-blue-50/70 via-white to-white px-5 py-4">
              <p className="text-xs font-bold uppercase tracking-[0.16em] text-blue-600">
                New ticket
              </p>

              <h2 className="mt-1 text-xl font-bold text-slate-950">Create Assisted Ticket</h2>

              <p className="mt-1 text-sm text-slate-500">
                Select the service and indicate whether the customer requires priority assistance.
              </p>
            </div>

            <div className="grid min-h-0 flex-1 gap-x-6 gap-y-4 overflow-hidden p-5 lg:grid-cols-2 lg:content-start">
              <section>
                <div className="mb-4">
                  <p className="text-xs font-bold uppercase tracking-[0.16em] text-slate-400">
                    Service
                  </p>

                  <h3 className="mt-1 text-base font-bold text-slate-900">
                    Select destination service
                  </h3>
                </div>

                <label className="block">
                  <span className="mb-2 block text-sm font-bold text-slate-700">
                    Queue service <span className="text-red-500">*</span>
                  </span>

                  <select
                    required
                    value={form.data.queue_service_id}
                    onChange={(event) => form.setData("queue_service_id", event.target.value)}
                    className="w-full rounded-xl border-slate-200 bg-slate-50 px-4 py-3 text-sm shadow-sm transition focus:border-blue-500 focus:bg-white focus:ring-blue-500"
                  >
                    <option value="">Select a service</option>

                    {queueServices.map((service) => (
                      <option key={service.id} value={service.id}>
                        {service.name} ({service.code})
                      </option>
                    ))}
                  </select>
                </label>
              </section>

              <section className="lg:border-l lg:border-slate-100 lg:pl-6">
                <div className="mb-4">
                  <p className="text-xs font-bold uppercase tracking-[0.16em] text-slate-400">
                    Priority support
                  </p>

                  <h3 className="mt-1 text-base font-bold text-slate-900">
                    Assistance requirements
                  </h3>
                </div>

                <label
                  className={`flex cursor-pointer items-start justify-between gap-4 rounded-xl border p-4 transition ${
                    requestAssistance
                      ? "border-blue-200 bg-blue-50/70"
                      : "border-slate-200 bg-slate-50 hover:bg-white"
                  }`}
                >
                  <div className="flex gap-4">
                    <div
                      className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl text-sm font-black ${
                        requestAssistance ? "bg-blue-600 text-white" : "bg-white text-slate-500"
                      }`}
                    >
                      A
                    </div>

                    <div>
                      <p className="text-sm font-bold text-slate-900">Request assistance</p>

                      <p className="mt-1 max-w-xl text-xs leading-5 text-slate-500">
                        Use this option for senior adults, disability, pregnancy, or a scheduled
                        appointment.
                      </p>
                    </div>
                  </div>

                  <input
                    type="checkbox"
                    checked={requestAssistance}
                    onChange={(event) => handleAssistanceChange(event.target.checked)}
                    className="mt-2 h-5 w-5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                  />
                </label>

                {requestAssistance && (
                  <div className="mt-3 rounded-xl border border-blue-100 bg-blue-50/40 p-4">
                    <label className="block">
                      <span className="mb-2 block text-sm font-bold text-slate-700">
                        Assistance type <span className="text-red-500">*</span>
                      </span>

                      <select
                        required
                        value={form.data.assistance_type}
                        onChange={(event) => form.setData("assistance_type", event.target.value)}
                        className="w-full rounded-xl border-slate-200 bg-white px-4 py-3 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                      >
                        <option value="">Select assistance type</option>

                        {assistanceTypes.map((assistanceType) => (
                          <option key={assistanceType} value={assistanceType}>
                            {assistanceLabels[assistanceType] ?? assistanceType}
                          </option>
                        ))}
                      </select>

                      <p className="mt-2 text-xs leading-5 text-slate-500">
                        Assistance requests may be verified at the service window.
                      </p>
                    </label>
                  </div>
                )}
              </section>

              <section className="lg:col-span-2">
                <div className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3">
                  <p className="text-xs font-bold uppercase tracking-[0.16em] text-slate-400">
                    Ticket summary
                  </p>

                  <div className="mt-2 grid gap-4 sm:grid-cols-2">
                    <div>
                      <p className="text-xs font-medium text-slate-500">Service</p>

                      <p className="mt-1 text-sm font-bold text-slate-900">
                        {selectedService
                          ? `${selectedService.name} (${selectedService.code})`
                          : "Not selected"}
                      </p>
                    </div>

                    <div>
                      <p className="text-xs font-medium text-slate-500">Priority handling</p>

                      <p className="mt-1 text-sm font-bold text-slate-900">
                        {requestAssistance
                          ? assistanceLabels[form.data.assistance_type] || "Select assistance type"
                          : "Normal"}
                      </p>
                    </div>
                  </div>
                </div>
              </section>
            </div>

            <div className="flex flex-col-reverse gap-3 border-t border-slate-100 bg-slate-50/70 px-5 py-3 sm:flex-row sm:justify-end">
              <button
                type="button"
                onClick={() => {
                  form.reset();
                  setRequestAssistance(false);
                }}
                disabled={form.processing}
                className="rounded-xl border border-slate-200 bg-white px-5 py-3 text-sm font-bold text-slate-600 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Clear
              </button>

              <button
                type="submit"
                disabled={!canSubmit}
                className="rounded-xl bg-blue-600 px-6 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {form.processing ? "Creating ticket..." : "Generate ticket"}
              </button>
            </div>
          </form>

          <aside className="flex min-h-0 flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <div className="shrink-0 border-b border-slate-100 px-4 py-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-bold uppercase tracking-[0.14em] text-slate-400">
                    Activity
                  </p>

                  <h2 className="mt-1 text-lg font-bold text-slate-950">Recent Tickets</h2>
                </div>

                <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-bold text-slate-600">
                  {recentTickets.length}
                </span>
              </div>
            </div>

            <div className="min-h-0 flex-1 overflow-y-auto p-3">
              {recentTickets.length === 0 ? (
                <div className="rounded-xl border border-dashed border-slate-300 px-4 py-10 text-center">
                  <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-slate-100 text-sm font-bold text-slate-400">
                    0
                  </div>

                  <p className="mt-3 text-sm font-bold text-slate-700">No tickets yet</p>

                  <p className="mt-1 text-xs text-slate-500">
                    Newly created tickets will appear here.
                  </p>
                </div>
              ) : (
                <div className="space-y-3">
                  {recentTickets.map((ticket) => (
                    <article
                      key={ticket.id}
                      className="rounded-xl border border-slate-200 bg-white p-4 transition hover:border-blue-200 hover:shadow-sm"
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <p className="text-lg font-black tracking-tight text-slate-950">
                            {ticket.ticket_number}
                          </p>

                          <p className="mt-1 text-xs font-semibold text-slate-500">
                            {ticket.service.name}
                          </p>
                        </div>

                        <span
                          className={`inline-flex rounded-full px-2.5 py-1 text-[10px] font-bold ring-1 ring-inset ${statusClasses(
                            ticket.status,
                          )}`}
                        >
                          {formatStatus(ticket.status)}
                        </span>
                      </div>

                      <div className="mt-4 flex flex-wrap gap-2">
                        <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[10px] font-semibold text-slate-600">
                          {ticket.assistance_type
                            ? assistanceLabels[ticket.assistance_type]
                            : "Normal priority"}
                        </span>

                        <span className="rounded-full bg-blue-50 px-2.5 py-1 text-[10px] font-semibold text-blue-700">
                          {ticket.intake_source === "self_service" ? "Self-service" : "Assisted"}
                        </span>
                      </div>

                      <div className="mt-4 flex items-center justify-between border-t border-slate-100 pt-3">
                        <span className="text-xs text-slate-400">
                          Created {formatCreatedAt(ticket.created_at)}
                        </span>

                        {ticket.status === "pending" && (
                          <button
                            type="button"
                            onClick={() => handleCancelTicket(ticket)}
                            className="rounded-lg px-3 py-1.5 text-xs font-bold text-red-600 transition hover:bg-red-50"
                          >
                            Cancel
                          </button>
                        )}
                      </div>
                    </article>
                  ))}
                </div>
              )}
            </div>
          </aside>
        </div>
      </section>
    </AppLayout>
  );
}
