import { router, useForm, usePage } from "@inertiajs/react"
import type { FormEvent } from "react"
import { useEffect, useState } from "react"

import AppLayout from "../../layouts/AppLayout"
import type { FlashData } from "../../types"

type QueueServiceRecord = {
  id: number
  name: string
  code: string
}

type ServiceWindowRecord = {
  id: number
  name: string
  code: string
  queue_service: QueueServiceRecord
}

type PendingTicketRecord = {
  id: number
  ticket_number: string
  priority: string
  assistance_type: string | null
  intake_source: string
  created_at: string
}

type CurrentCalledTicketRecord = {
  id: number
  ticket_number: string
  priority: string
  assistance_type: string | null
  intake_source: string
  called_at: string | null
  assigned_agent: {
    id: number
    name: string
  }
  service_window: {
    id: number
    name: string
    code: string
  }
  queue_service: QueueServiceRecord
}

type AgentQueueProps = {
  service_windows: ServiceWindowRecord[]
  selected_service_window: ServiceWindowRecord | null
  pending_tickets: PendingTicketRecord[]
  current_called_ticket: CurrentCalledTicketRecord | null
}

type CallNextFormData = {
  service_window_id: string
}

type SharedPageProps = {
  flash?: FlashData
}

const priorityLabels: Record<string, string> = {
  emergency: "Emergency",
  disability: "Disability",
  senior: "Senior adult",
  pregnancy: "Pregnancy",
  appointment: "Scheduled appointment",
  normal: "Normal",
}

const assistanceLabels: Record<string, string> = {
  disability: "Disability",
  senior: "Senior adult",
  pregnancy: "Pregnancy",
  appointment: "Scheduled appointment",
}

function formatTime(dateTime: string | null) {
  if (!dateTime) return "Not available"

  return new Date(dateTime).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  })
}

function formatIntakeSource(intakeSource: string) {
  return intakeSource === "self_service" ? "Self-service" : "Assisted"
}

export default function AgentQueue({
  service_windows: serviceWindows,
  selected_service_window: selectedServiceWindow,
  pending_tickets: pendingTickets,
  current_called_ticket: currentCalledTicket,
}: AgentQueueProps) {
  const { props } = usePage<SharedPageProps>()
  const flash = props.flash
  const [showNotice, setShowNotice] = useState(Boolean(flash?.notice))

  useEffect(() => {
    if (!flash?.notice) {
      setShowNotice(false)
      return
    }

    setShowNotice(true)

    const timeoutId = window.setTimeout(() => {
      setShowNotice(false)
    }, 10_000)

    return () => window.clearTimeout(timeoutId)
  }, [flash?.notice])

  const form = useForm<CallNextFormData>({
    service_window_id: selectedServiceWindow?.id.toString() ?? "",
  })

  const handleServiceWindowChange = (serviceWindowId: string) => {
    form.setData("service_window_id", serviceWindowId)

    if (serviceWindowId === "") {
      return
    }

    router.get(
      "/agent-queue",
      { service_window_id: serviceWindowId },
      {
        preserveScroll: true,
        preserveState: false,
        replace: true,
      },
    )
  }

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (!selectedServiceWindow) return

    form.transform((formData) => ({
      service_window_id: formData.service_window_id,
    }))

    form.post("/agent-queue/call-next", {
      preserveScroll: true,
    })
  }

  const canCallNext =
    selectedServiceWindow !== null &&
    pendingTickets.length > 0 &&
    !form.processing

  return (
    <AppLayout>
      <section className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-slate-950">
            Agent Queue
          </h1>

          <p className="mt-2 text-sm text-slate-600">
            Select an active service window and call the next pending ticket.
          </p>
        </div>

        {showNotice && flash?.notice && (
          <div className="rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm font-medium text-green-700">
            {flash.notice}
          </div>
        )}

        {flash?.alert && (
          <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {flash.alert}
          </div>
        )}

        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <label className="block max-w-xl">
            <span className="text-sm font-semibold text-slate-700">
              Service Window
            </span>

            <select
              value={selectedServiceWindow?.id.toString() ?? ""}
              onChange={(event) =>
                handleServiceWindowChange(event.target.value)
              }
              className="mt-2 w-full rounded-lg border-slate-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
            >
              {serviceWindows.length === 0 && (
                <option value="">No active service windows available</option>
              )}

              {serviceWindows.map((serviceWindow) => (
                <option key={serviceWindow.id} value={serviceWindow.id}>
                  {serviceWindow.name} ({serviceWindow.code}) —{" "}
                  {serviceWindow.queue_service.name}
                </option>
              ))}
            </select>
          </label>

          {selectedServiceWindow && (
            <div className="mt-5 flex flex-wrap gap-3">
              <span className="rounded-full bg-blue-50 px-3 py-1.5 text-sm font-semibold text-blue-700">
                Window: {selectedServiceWindow.code}
              </span>

              <span className="rounded-full bg-slate-100 px-3 py-1.5 text-sm font-semibold text-slate-700">
                Service: {selectedServiceWindow.queue_service.name} (
                {selectedServiceWindow.queue_service.code})
              </span>

              <span className="rounded-full bg-amber-50 px-3 py-1.5 text-sm font-semibold text-amber-700">
                Pending: {pendingTickets.length}
              </span>
            </div>
          )}
        </div>

        <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_320px]">
          <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-5">
              <div>
                <h2 className="text-lg font-bold text-slate-950">
                  Pending Tickets
                </h2>

                <p className="mt-1 text-sm text-slate-500">
                  Ordered by priority and arrival time.
                </p>
              </div>

              <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                {pendingTickets.length}
              </span>
            </div>

            {pendingTickets.length === 0 ? (
              <div className="px-6 py-12 text-center">
                <p className="text-sm font-medium text-slate-600">
                  {selectedServiceWindow
                    ? "No pending tickets are available for this service."
                    : "No service window is selected."}
                </p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-200">
                  <thead className="bg-slate-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Ticket number
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Priority
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Assistance
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Waiting since
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                        Intake source
                      </th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100 bg-white">
                    {pendingTickets.map((ticket) => (
                      <tr key={ticket.id}>
                        <td className="whitespace-nowrap px-6 py-4 text-sm font-bold text-slate-950">
                          {ticket.ticket_number}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                          {priorityLabels[ticket.priority] ?? ticket.priority}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                          {ticket.assistance_type
                            ? assistanceLabels[ticket.assistance_type] ??
                              ticket.assistance_type
                            : "None"}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                          {formatTime(ticket.created_at)}
                        </td>

                        <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                          {formatIntakeSource(ticket.intake_source)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}

            <form
              onSubmit={submit}
              className="flex justify-end border-t border-slate-200 bg-slate-50 px-6 py-4"
            >
              <button
                type="submit"
                disabled={!canCallNext}
                className="rounded-lg bg-blue-600 px-5 py-2 text-sm font-semibold text-white shadow-sm hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
              >
                {form.processing ? "Calling..." : "Call next"}
              </button>
            </form>
          </div>

          <aside className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
            <div className="border-b border-slate-200 pb-4">
              <h2 className="font-bold text-slate-950">
                Currently Called
              </h2>

              <p className="mt-1 text-xs text-slate-500">
                Latest ticket called at this window
              </p>
            </div>

            {currentCalledTicket ? (
              <div className="mt-5">
                <p className="text-3xl font-bold tracking-tight text-blue-600">
                  {currentCalledTicket.ticket_number}
                </p>

                <dl className="mt-5 space-y-4 text-sm">
                  <div>
                    <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Service
                    </dt>
                    <dd className="mt-1 font-medium text-slate-700">
                      {currentCalledTicket.queue_service.name}
                    </dd>
                  </div>

                  <div>
                    <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Window
                    </dt>
                    <dd className="mt-1 font-medium text-slate-700">
                      {currentCalledTicket.service_window.name} (
                      {currentCalledTicket.service_window.code})
                    </dd>
                  </div>

                  <div>
                    <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Agent
                    </dt>
                    <dd className="mt-1 font-medium text-slate-700">
                      {currentCalledTicket.assigned_agent.name}
                    </dd>
                  </div>

                  <div>
                    <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Called at
                    </dt>
                    <dd className="mt-1 font-medium text-slate-700">
                      {formatTime(currentCalledTicket.called_at)}
                    </dd>
                  </div>
                </dl>
              </div>
            ) : (
              <div className="mt-5 rounded-lg border border-dashed border-slate-300 px-4 py-8 text-center">
                <p className="text-sm font-medium text-slate-600">
                  No ticket has been called at this window.
                </p>
              </div>
            )}
          </aside>
        </div>
      </section>
    </AppLayout>
  )
}
