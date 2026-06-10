import { router, useForm, usePage } from "@inertiajs/react"
import type { FormEvent } from "react"
import { useEffect, useMemo, useState } from "react"

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

type ActiveTicketRecord = {
  id: number
  ticket_number: string
  priority: string
  assistance_type: string | null
  intake_source: string
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
  called_at?: string | null
  started_at?: string | null
}

type AgentActiveTicketRecord = {
  id: number
  ticket_number: string
  status: "called" | "in_attention"
  service_window: {
    id: number
    name: string
    code: string
  }
}

type AgentQueueProps = {
  service_windows: ServiceWindowRecord[]
  selected_service_window: ServiceWindowRecord | null
  pending_tickets: PendingTicketRecord[]
  current_called_ticket: ActiveTicketRecord | null
  current_in_attention_ticket: ActiveTicketRecord | null
  agent_active_ticket: AgentActiveTicketRecord | null
  selected_service_window_busy: boolean
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

function formatTime(dateTime: string | null | undefined) {
  if (!dateTime) return "Not available"

  return new Date(dateTime).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  })
}

function formatIntakeSource(intakeSource: string) {
  return intakeSource === "self_service" ? "Self-service" : "Assisted"
}

function getStatusLabel(status: "called" | "in_attention" | null) {
  if (status === "called") return "Called"
  if (status === "in_attention") return "In attention"
  return "No active ticket"
}

export default function AgentQueue({
  service_windows: serviceWindows,
  selected_service_window: selectedServiceWindow,
  pending_tickets: pendingTickets,
  current_called_ticket: currentCalledTicket,
  current_in_attention_ticket: currentInAttentionTicket,
  agent_active_ticket: agentActiveTicket,
  selected_service_window_busy: selectedServiceWindowBusy,
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

  const callNextForm = useForm<CallNextFormData>({
    service_window_id: selectedServiceWindow?.id.toString() ?? "",
  })

  const startAttentionForm = useForm({})
  const finishAttentionForm = useForm({})

  const activeTicketStatus = useMemo<"called" | "in_attention" | null>(() => {
    if (currentInAttentionTicket) return "in_attention"
    if (currentCalledTicket) return "called"
    return null
  }, [currentCalledTicket, currentInAttentionTicket])

  const activeTicket = currentInAttentionTicket ?? currentCalledTicket
  const agentHasActiveTicket = agentActiveTicket !== null

  const handleServiceWindowChange = (serviceWindowId: string) => {
    callNextForm.setData("service_window_id", serviceWindowId)

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

  const submitCallNext = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()

    if (!selectedServiceWindow) return

    callNextForm.transform((formData) => ({
      service_window_id: formData.service_window_id,
    }))

    callNextForm.post("/agent-queue/call-next", {
      preserveScroll: true,
    })
  }

  const handleStartAttention = () => {
    if (!currentCalledTicket) return

    startAttentionForm.patch(
      `/agent-queue/tickets/${currentCalledTicket.id}/start`,
      {
        preserveScroll: true,
      },
    )
  }

  const handleFinishAttention = () => {
    if (!currentInAttentionTicket) return

    finishAttentionForm.patch(
      `/agent-queue/tickets/${currentInAttentionTicket.id}/finish`,
      {
        preserveScroll: true,
      },
    )
  }

  const canCallNext =
    selectedServiceWindow !== null &&
    pendingTickets.length > 0 &&
    !agentHasActiveTicket &&
    !selectedServiceWindowBusy &&
    !callNextForm.processing

  return (
    <AppLayout>
      <section className="space-y-6">
        <div className="flex flex-col gap-4 xl:flex-row xl:items-start xl:justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight text-slate-950">
              Agent Queue
            </h1>

            <p className="mt-2 text-sm text-slate-600">
              Manage the tickets assigned to your service window in real time.
            </p>
          </div>

          <form onSubmit={submitCallNext}>
            <button
              type="submit"
              disabled={!canCallNext}
              className="inline-flex min-w-52 items-center justify-center rounded-xl bg-blue-600 px-6 py-3 text-sm font-semibold uppercase tracking-wide text-white shadow-sm transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
            >
              {callNextForm.processing
                ? "Calling..."
                : selectedServiceWindowBusy
                  ? "Window busy"
                  : agentHasActiveTicket
                    ? "Active ticket"
                    : "Call next"}
            </button>
          </form>
        </div>

        {showNotice && flash?.notice && (
          <div className="rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm font-medium text-green-700">
            {flash.notice}
          </div>
        )}

        {flash?.alert && (
          <div className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium text-red-700">
            {flash.alert}
          </div>
        )}

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="grid gap-5 xl:grid-cols-[minmax(0,340px)_1fr]">
            <div>
              <label className="block">
                <span className="text-sm font-semibold text-slate-700">
                  Service window
                </span>

                <select
                  value={selectedServiceWindow?.id.toString() ?? ""}
                  onChange={(event) =>
                    handleServiceWindowChange(event.target.value)
                  }
                  className="mt-2 w-full rounded-xl border-slate-300 text-sm shadow-sm focus:border-blue-500 focus:ring-blue-500"
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
            </div>

            <div className="grid gap-3 md:grid-cols-4">
              <div className="rounded-2xl bg-slate-50 px-4 py-3">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Agent
                </p>
                <p className="mt-2 text-sm font-semibold text-slate-900">
                  {activeTicket
                    ? activeTicket.assigned_agent.name
                    : agentActiveTicket
                      ? `Busy at ${agentActiveTicket.service_window.code}`
                      : "Ready"}
                </p>
              </div>

              <div className="rounded-2xl bg-slate-50 px-4 py-3">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Service window
                </p>
                <p className="mt-2 text-sm font-semibold text-slate-900">
                  {selectedServiceWindow
                    ? `${selectedServiceWindow.name} (${selectedServiceWindow.code})`
                    : "Not selected"}
                </p>
              </div>

              <div className="rounded-2xl bg-slate-50 px-4 py-3">
                <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">
                  Service
                </p>
                <p className="mt-2 text-sm font-semibold text-slate-900">
                  {selectedServiceWindow
                    ? selectedServiceWindow.queue_service.name
                    : "Not selected"}
                </p>
              </div>

              <div className="rounded-2xl bg-green-50 px-4 py-3">
                <p className="text-xs font-semibold uppercase tracking-wide text-green-600">
                  Queue status
                </p>
                <p className="mt-2 text-sm font-semibold text-green-700">
                  Pending tickets: {pendingTickets.length}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-200 pb-4">
            <div>
              <h2 className="text-lg font-bold text-slate-950">
                Current Attention
              </h2>

              <p className="mt-1 text-sm text-slate-500">
                Active lifecycle for the selected service window.
              </p>
            </div>

            <span
              className={`rounded-full px-3 py-1 text-xs font-semibold uppercase tracking-wide ${
                activeTicketStatus === "in_attention"
                  ? "bg-green-100 text-green-700"
                  : activeTicketStatus === "called"
                    ? "bg-blue-100 text-blue-700"
                    : "bg-slate-100 text-slate-600"
              }`}
            >
              {getStatusLabel(activeTicketStatus)}
            </span>
          </div>

          {activeTicket ? (
            <div className="mt-6 grid gap-6 xl:grid-cols-[minmax(0,1fr)_260px]">
              <div>
                <p className="text-sm font-medium text-slate-500">
                  Ticket number
                </p>

                <p className="mt-2 text-5xl font-bold tracking-tight text-slate-950">
                  {activeTicket.ticket_number}
                </p>

                <div className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                  <div className="rounded-2xl border border-slate-200 px-4 py-3">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Service
                    </p>
                    <p className="mt-2 text-sm font-semibold text-slate-800">
                      {activeTicket.queue_service.name}
                    </p>
                  </div>

                  <div className="rounded-2xl border border-slate-200 px-4 py-3">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Window
                    </p>
                    <p className="mt-2 text-sm font-semibold text-slate-800">
                      {activeTicket.service_window.name} (
                      {activeTicket.service_window.code})
                    </p>
                  </div>

                  <div className="rounded-2xl border border-slate-200 px-4 py-3">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Priority
                    </p>
                    <p className="mt-2 text-sm font-semibold text-slate-800">
                      {priorityLabels[activeTicket.priority] ??
                        activeTicket.priority}
                    </p>
                  </div>

                  <div className="rounded-2xl border border-slate-200 px-4 py-3">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Intake source
                    </p>
                    <p className="mt-2 text-sm font-semibold text-slate-800">
                      {formatIntakeSource(activeTicket.intake_source)}
                    </p>
                  </div>
                </div>

                <div className="mt-4 grid gap-4 sm:grid-cols-2">
                  <div className="rounded-2xl border border-slate-200 px-4 py-3">
                    <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                      Assistance
                    </p>
                    <p className="mt-2 text-sm font-semibold text-slate-800">
                      {activeTicket.assistance_type
                        ? assistanceLabels[activeTicket.assistance_type] ??
                          activeTicket.assistance_type
                        : "None"}
                    </p>
                  </div>

                  {activeTicketStatus === "called" ? (
                    <div className="rounded-2xl border border-slate-200 px-4 py-3">
                      <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                        Called at
                      </p>
                      <p className="mt-2 text-sm font-semibold text-slate-800">
                        {formatTime(activeTicket.called_at)}
                      </p>
                    </div>
                  ) : (
                    <div className="rounded-2xl border border-slate-200 px-4 py-3">
                      <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                        Started at
                      </p>
                      <p className="mt-2 text-sm font-semibold text-slate-800">
                        {formatTime(activeTicket.started_at)}
                      </p>
                    </div>
                  )}
                </div>
              </div>

              <div className="flex flex-col justify-between rounded-2xl border border-dashed border-slate-300 bg-slate-50 p-5">
                <div>
                  <p className="text-sm font-semibold text-slate-700">
                    Next action
                  </p>

                  <p className="mt-2 text-sm text-slate-500">
                    Continue the normal attention lifecycle for this ticket.
                  </p>
                </div>

                <div className="mt-6">
                  {activeTicketStatus === "called" && (
                    <button
                      type="button"
                      onClick={handleStartAttention}
                      disabled={startAttentionForm.processing}
                      className="w-full rounded-xl bg-slate-900 px-4 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      {startAttentionForm.processing
                        ? "Starting..."
                        : "Start attention"}
                    </button>
                  )}

                  {activeTicketStatus === "in_attention" && (
                    <button
                      type="button"
                      onClick={handleFinishAttention}
                      disabled={finishAttentionForm.processing}
                      className="w-full rounded-xl bg-blue-600 px-4 py-3 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                    >
                      {finishAttentionForm.processing
                        ? "Finishing..."
                        : "Finish attention"}
                    </button>
                  )}
                </div>
              </div>
            </div>
          ) : (
            <div className="mt-6 rounded-2xl border border-dashed border-slate-300 px-6 py-12 text-center">
              <p className="text-base font-semibold text-slate-700">
                No active ticket at this moment.
              </p>
              <p className="mt-2 text-sm text-slate-500">
                Call the next ticket to begin the attention lifecycle.
              </p>
            </div>
          )}
        </div>

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-200 px-6 py-5">
            <div>
              <h2 className="text-lg font-bold text-slate-950">Waiting Queue</h2>

              <p className="mt-1 text-sm text-slate-500">
                Tickets waiting for this service, ordered by priority and arrival
                time.
              </p>
            </div>

            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              {pendingTickets.length} tickets
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
                      Ticket
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                      Service
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                      Priority
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                      Waiting since
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                      Status
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-100 bg-white">
                  {pendingTickets.map((ticket) => (
                    <tr key={ticket.id}>
                      <td className="whitespace-nowrap px-6 py-4 text-sm font-bold text-blue-700">
                        {ticket.ticket_number}
                      </td>

                      <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                        {selectedServiceWindow?.queue_service.name ?? "Service"}
                      </td>

                      <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                        {priorityLabels[ticket.priority] ?? ticket.priority}
                      </td>

                      <td className="whitespace-nowrap px-6 py-4 text-sm text-slate-600">
                        {formatTime(ticket.created_at)}
                      </td>

                      <td className="whitespace-nowrap px-6 py-4 text-sm">
                        <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">
                          Pending
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </section>
    </AppLayout>
  )
}
