import { useForm, usePage } from "@inertiajs/react";
import type { FormEvent } from "react";
import { useEffect, useState } from "react";

import GuestLayout from "../../../layouts/GuestLayout";
import type { FlashData } from "../../../types";

type QueueServiceRecord = {
  id: number;
  name: string;
  code: string;
};

type GeneratedTicket = {
  ticket_number: string;
  service_name: string;
  assistance_type: string | null;
};

type SelfServiceTicketProps = {
  queue_services: QueueServiceRecord[];
  assistance_types: string[];
  generated_ticket: GeneratedTicket | null;
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

export default function NewSelfServiceTicket({
  queue_services: queueServices,
  assistance_types: assistanceTypes,
  generated_ticket: generatedTicket,
}: SelfServiceTicketProps) {
  const { props } = usePage<SharedPageProps>();
  const flash = props.flash;

  const [requestAssistance, setRequestAssistance] = useState(false);

  const form = useForm<TicketFormData>({
    queue_service_id: "",
    assistance_type: "",
  });

  useEffect(() => {
    if (!generatedTicket) return;

    const timeoutId = window.setTimeout(() => {
      window.location.href = "/self-service";
    }, 10_000);

    return () => window.clearTimeout(timeoutId);
  }, [generatedTicket]);

  const selectedService = queueServices.find(
    (service) => String(service.id) === form.data.queue_service_id,
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

    form.post("/self-service/tickets");
  };

  if (generatedTicket) {
    return (
      <GuestLayout>
        <main className="flex min-h-screen items-center justify-center bg-gradient-to-br from-sky-50 via-white to-emerald-50 px-6 py-10">
          <section className="w-full max-w-xl rounded-3xl border border-slate-200 bg-white px-8 py-10 text-center shadow-2xl shadow-slate-300/50">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-green-100 text-3xl text-green-700">
              ✓
            </div>

            <p className="mt-6 text-sm font-bold uppercase tracking-[0.2em] text-blue-600">
              Ticket created
            </p>

            <h1 className="mt-4 text-6xl font-black tracking-tight text-slate-950 sm:text-7xl">
              {generatedTicket.ticket_number}
            </h1>

            <p className="mt-5 text-lg font-semibold text-slate-700">
              {generatedTicket.service_name}
            </p>

            {generatedTicket.assistance_type && (
              <div className="mx-auto mt-4 inline-flex rounded-full bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700">
                Assistance:{" "}
                {assistanceLabels[generatedTicket.assistance_type] ??
                  generatedTicket.assistance_type}
              </div>
            )}

            <p className="mx-auto mt-7 max-w-sm text-sm leading-6 text-slate-500">
              Please wait until your ticket number and service window are shown on the public
              screen.
            </p>

            <p className="mt-4 text-xs font-semibold text-slate-400">
              Returning to self-service automatically in 10 seconds.
            </p>

            <a
              href="/self-service"
              className="mt-8 inline-flex w-full items-center justify-center rounded-xl bg-blue-600 px-6 py-4 text-base font-bold text-white shadow-lg shadow-blue-600/20 transition hover:bg-blue-700"
            >
              Create another ticket
            </a>
          </section>
        </main>
      </GuestLayout>
    );
  }

  return (
    <GuestLayout>
      <main className="min-h-screen bg-gradient-to-br from-sky-50 via-white to-emerald-50 px-5 py-8 sm:px-8">
        <div className="mx-auto max-w-5xl">
          <header className="mb-8 text-center">
            <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-blue-600 text-xl font-black text-white shadow-lg shadow-blue-600/20">
              Q
            </div>

            <h1 className="mt-4 text-3xl font-black tracking-tight text-slate-950 sm:text-4xl">
              Welcome to QueueCare AI
            </h1>

            <p className="mt-3 text-base text-slate-600">
              Select the service you need to generate your ticket.
            </p>
          </header>

          {flash?.alert && (
            <div className="mb-6 rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm font-semibold text-red-700">
              {flash.alert}
            </div>
          )}

          <form
            onSubmit={submit}
            className="overflow-hidden rounded-3xl border border-slate-200 bg-white shadow-2xl shadow-slate-300/40"
          >
            <div className="border-b border-slate-200 px-6 py-6 sm:px-8">
              <p className="text-sm font-bold uppercase tracking-[0.16em] text-blue-600">Step 1</p>

              <h2 className="mt-2 text-2xl font-black text-slate-950">Select a service</h2>

              <p className="mt-2 text-sm text-slate-500">
                Your ticket priority will be normal unless assistance is requested.
              </p>
            </div>

            <div className="px-6 py-6 sm:px-8">
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {queueServices.map((service) => {
                  const isSelected = form.data.queue_service_id === String(service.id);

                  return (
                    <button
                      key={service.id}
                      type="button"
                      onClick={() => form.setData("queue_service_id", String(service.id))}
                      className={`rounded-2xl border-2 px-5 py-5 text-left transition ${
                        isSelected
                          ? "border-blue-600 bg-blue-50 shadow-md shadow-blue-600/10"
                          : "border-slate-200 bg-white hover:border-blue-300 hover:bg-slate-50"
                      }`}
                    >
                      <span
                        className={`inline-flex rounded-lg px-2.5 py-1 text-xs font-black ${
                          isSelected ? "bg-blue-600 text-white" : "bg-slate-100 text-slate-600"
                        }`}
                      >
                        {service.code}
                      </span>

                      <span className="mt-4 block text-base font-bold text-slate-900">
                        {service.name}
                      </span>
                    </button>
                  );
                })}
              </div>

              <div className="mt-8 rounded-2xl border border-slate-200 bg-slate-50 p-5">
                <label className="flex cursor-pointer items-start gap-4">
                  <input
                    type="checkbox"
                    checked={requestAssistance}
                    onChange={(event) => handleAssistanceChange(event.target.checked)}
                    className="mt-1 h-5 w-5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                  />

                  <span>
                    <span className="block text-base font-bold text-slate-900">
                      Request assistance
                    </span>

                    <span className="mt-1 block text-sm leading-6 text-slate-500">
                      Select this option for senior adults, disability, pregnancy, or a scheduled
                      appointment.
                    </span>
                  </span>
                </label>

                {requestAssistance && (
                  <div className="mt-5 border-t border-slate-200 pt-5">
                    <label className="block">
                      <span className="text-sm font-bold text-slate-700">Assistance type</span>

                      <select
                        required
                        value={form.data.assistance_type}
                        onChange={(event) => form.setData("assistance_type", event.target.value)}
                        className="mt-2 w-full rounded-xl border-slate-300 bg-white px-4 py-3 text-base shadow-sm focus:border-blue-500 focus:ring-blue-500"
                      >
                        <option value="">Select an option</option>

                        {assistanceTypes.map((assistanceType) => (
                          <option key={assistanceType} value={assistanceType}>
                            {assistanceLabels[assistanceType] ?? assistanceType}
                          </option>
                        ))}
                      </select>
                    </label>

                    <p className="mt-3 text-xs leading-5 text-slate-500">
                      Assistance requests may be verified at the service window.
                    </p>
                  </div>
                )}
              </div>
            </div>

            <div className="border-t border-slate-200 bg-slate-50 px-6 py-6 sm:px-8">
              <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                <div>
                  <p className="text-xs font-bold uppercase tracking-wide text-slate-400">
                    Selected service
                  </p>

                  <p className="mt-1 font-bold text-slate-800">
                    {selectedService
                      ? `${selectedService.name} (${selectedService.code})`
                      : "No service selected"}
                  </p>
                </div>

                <button
                  type="submit"
                  disabled={!canSubmit}
                  className="inline-flex min-h-14 items-center justify-center rounded-xl bg-blue-600 px-8 py-4 text-base font-black text-white shadow-lg shadow-blue-600/20 transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  {form.processing ? "Generating..." : "Generate ticket"}
                </button>
              </div>
            </div>
          </form>

          <p className="mt-6 text-center text-sm text-slate-500">
            Need immediate help? Please ask a staff member.
          </p>
        </div>
      </main>
    </GuestLayout>
  );
}
