import { router, useForm, usePage } from "@inertiajs/react";
import type { FormEvent } from "react";
import { useState } from "react";

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
      <section className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-950">
            Assisted Ticket Intake
          </h1>

          <p className="mt-2 text-sm text-slate-600">
            Create a ticket for someone who needs help using the self-service process.
          </p>
        </div>

        {flash?.notice && (
          <div className="rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm font-medium text-green-700">
            {flash.notice}
          </div>
        )}

        {flash?.alert && (
          <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {flash.alert}
          </div>
        )}

        <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_320px]">
          <form
            onSubmit={submit}
            className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm"
          >
            <div className="border-b border-slate-200 px-6 py-5">
              <h2 className="text-lg font-bold text-slate-950">Create Assisted Ticket</h2>

              <p className="mt-1 text-sm text-slate-500">
                The ticket will use normal priority unless assistance is requested.
              </p>
            </div>

            <div className="space-y-6 px-6 py-6">
              <label className="block">
                <span className="text-sm font-semibold text-slate-700">
                  Service <span className="text-red-500">*</span>
                </span>

                <select
                  required
                  value={form.data.queue_service_id}
                  onChange={(event) => form.setData("queue_service_id", event.target.value)}
                  className="mt-2 w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                >
                  <option value="">Select a service</option>

                  {queueServices.map((service) => (
                    <option key={service.id} value={service.id}>
                      {service.name} ({service.code})
                    </option>
                  ))}
                </select>
              </label>

              <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
                <label className="flex cursor-pointer items-start gap-3">
                  <input
                    type="checkbox"
                    checked={requestAssistance}
                    onChange={(event) => handleAssistanceChange(event.target.checked)}
                    className="mt-1 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                  />

                  <span>
                    <span className="block text-sm font-semibold text-slate-800">
                      Request assistance
                    </span>

                    <span className="mt-1 block text-xs leading-5 text-slate-500">
                      Use this option for senior adults, disability, pregnancy, or a scheduled
                      appointment.
                    </span>
                  </span>
                </label>

                {requestAssistance && (
                  <label className="mt-4 block border-t border-slate-200 pt-4">
                    <span className="text-sm font-semibold text-slate-700">
                      Assistance type <span className="text-red-500">*</span>
                    </span>

                    <select
                      required
                      value={form.data.assistance_type}
                      onChange={(event) => form.setData("assistance_type", event.target.value)}
                      className="mt-2 w-full rounded-lg border-slate-300 bg-white text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    >
                      <option value="">Select assistance type</option>

                      {assistanceTypes.map((assistanceType) => (
                        <option key={assistanceType} value={assistanceType}>
                          {assistanceLabels[assistanceType] ?? assistanceType}
                        </option>
                      ))}
                    </select>

                    <p className="mt-2 text-xs text-slate-500">
                      Assistance requests may be verified at the service window.
                    </p>
                  </label>
                )}
              </div>
            </div>

            <div className="flex justify-end gap-3 border-t border-slate-200 bg-slate-50 px-6 py-4">
              <button
                type="button"
                onClick={() => {
                  form.reset();
                  setRequestAssistance(false);
                }}
                disabled={form.processing}
                className="rounded-lg px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-200 disabled:cursor-not-allowed disabled:opacity-50"
              >
                Clear
              </button>

              <button
                type="submit"
                disabled={!canSubmit}
                className="rounded-lg bg-blue-600 px-5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {form.processing ? "Creating..." : "Generate ticket"}
              </button>
            </div>
          </form>

          <aside className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-200 pb-4">
              <div>
                <h2 className="font-bold text-slate-950">Recent Tickets</h2>

                <p className="mt-1 text-xs text-slate-500">Latest tickets in the system</p>
              </div>

              <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                {recentTickets.length}
              </span>
            </div>

            <div className="mt-4 space-y-3">
              {recentTickets.length === 0 ? (
                <div className="rounded-lg border border-dashed border-slate-300 px-4 py-8 text-center">
                  <p className="text-sm font-medium text-slate-600">No tickets created yet.</p>
                </div>
              ) : (
                recentTickets.map((ticket) => (
                  <article key={ticket.id} className="border-l-2 border-blue-600 py-1 pl-4">
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="font-bold text-slate-950">{ticket.ticket_number}</p>

                        <p className="mt-1 text-xs font-medium text-slate-600">
                          {ticket.service.name}
                        </p>
                      </div>

                      <div className="flex flex-col items-end gap-2">
                        <span className="rounded-full bg-slate-100 px-2 py-1 text-[10px] font-semibold text-slate-600">
                          {ticket.assistance_type
                            ? assistanceLabels[ticket.assistance_type]
                            : "Normal"}
                        </span>

                        <span className="rounded-full bg-blue-50 px-2 py-1 text-[10px] font-semibold text-blue-700">
                          {formatStatus(ticket.status)}
                        </span>
                      </div>
                    </div>

                    <div className="mt-3 flex items-center justify-between text-xs text-slate-500">
                      <span>
                        {ticket.intake_source === "self_service" ? "Self-service" : "Assisted"}
                      </span>

                      <span>{formatCreatedAt(ticket.created_at)}</span>
                    </div>

                    {ticket.status === "pending" && (
                      <div className="mt-3 flex justify-end">
                        <button
                          type="button"
                          onClick={() => handleCancelTicket(ticket)}
                          className="rounded-lg px-3 py-1.5 text-xs font-semibold text-red-600 hover:bg-red-50"
                        >
                          Cancel
                        </button>
                      </div>
                    )}
                  </article>
                ))
              )}
            </div>
          </aside>
        </div>
      </section>
    </AppLayout>
  );
}
