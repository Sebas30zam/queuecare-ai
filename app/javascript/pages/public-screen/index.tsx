import { Head, router } from "@inertiajs/react";
import { useEffect } from "react";

import GuestLayout from "../../layouts/GuestLayout";

type QueueServiceRecord = {
  id: number;
  name: string;
  code: string;
};

type ServiceWindowRecord = {
  id: number;
  name: string;
  code: string;
};

type AssignedAgentRecord = {
  id: number;
  name: string;
};

type PublicScreenTicket = {
  id: number;
  ticket_number: string;
  status: "called" | "in_attention" | "attended" | "no_show";
  called_at: string;
  queue_service: QueueServiceRecord;
  service_window: ServiceWindowRecord | null;
  assigned_agent: AssignedAgentRecord | null;
};

type PublicScreenProps = {
  active_tickets: PublicScreenTicket[];
  recently_called_tickets: PublicScreenTicket[];
  generated_at: string;
};

function formatTime(dateTime: string) {
  return new Date(dateTime).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatStatus(status: PublicScreenTicket["status"]) {
  const statusLabels: Record<PublicScreenTicket["status"], string> = {
    called: "Called",
    in_attention: "In attention",
    attended: "Attended",
    no_show: "No-show",
  };

  return statusLabels[status];
}

function BellIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-8 w-8"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth="1.8"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        d="M14.857 17.082a23.85 23.85 0 0 0 5.454-1.31A8.97
        8.97 0 0 1 18 9.75V9a6 6 0 0 0-12 0v.75a8.97
        8.97 0 0 1-2.312 6.022c1.733.64 3.56 1.08
        5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714
        0m5.714 0a3 3 0 1 1-5.714 0"
      />
    </svg>
  );
}

function ClockIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-5 w-5"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth="1.8"
    >
      <circle cx="12" cy="12" r="8.5" />
      <path strokeLinecap="round" d="M12 7.5V12l3 2" />
    </svg>
  );
}

function MonitorIcon() {
  return (
    <svg
      aria-hidden="true"
      className="h-10 w-10"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      strokeWidth="1.7"
    >
      <rect x="3" y="4" width="18" height="13" rx="2" />
      <path strokeLinecap="round" d="M9 21h6M12 17v4" />
    </svg>
  );
}

function RecentTicketCard({
  ticket,
  highlighted,
}: {
  ticket: PublicScreenTicket;
  highlighted: boolean;
}) {
  return (
    <article
      className={[
        "rounded-xl border bg-slate-900/80 px-6 py-5",
        highlighted ? "border-slate-700 border-l-4 border-l-sky-400" : "border-slate-800",
      ].join(" ")}
    >
      <div className="grid grid-cols-[1fr_auto_1fr] items-center gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Ticket</p>

          <p
            className={[
              "mt-1 text-3xl font-extrabold leading-none",
              highlighted ? "text-white" : "text-slate-300",
            ].join(" ")}
          >
            {ticket.ticket_number}
          </p>
        </div>

        <span
          aria-hidden="true"
          className={highlighted ? "text-3xl text-sky-400" : "text-3xl text-slate-700"}
        >
          →
        </span>

        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">
            Service window
          </p>

          <p
            className={[
              "mt-1 text-2xl font-bold leading-none",
              highlighted ? "text-sky-400" : "text-slate-400",
            ].join(" ")}
          >
            {ticket.service_window?.name ?? "Not assigned"}
          </p>

          {ticket.service_window && (
            <p className="mt-1 text-sm text-slate-500">{ticket.service_window.code}</p>
          )}
        </div>
      </div>

      <div className="mt-4 flex items-center justify-between border-t border-slate-800 pt-3 text-xs text-slate-500">
        <span>{formatStatus(ticket.status)}</span>
        <span>{formatTime(ticket.called_at)}</span>
      </div>
    </article>
  );
}

export default function PublicScreen({
  active_tickets: activeTickets,
  recently_called_tickets: recentlyCalledTickets,
  generated_at: generatedAt,
}: PublicScreenProps) {
  useEffect(() => {
    const intervalId = window.setInterval(() => {
      router.reload({
        only: ["active_tickets", "recently_called_tickets", "generated_at"],
      });
    }, 5_000);

    return () => window.clearInterval(intervalId);
  }, []);

  const currentTicket = activeTickets[0] ?? null;

  const recentTickets = recentlyCalledTickets
    .filter((ticket) => ticket.id !== currentTicket?.id)
    .slice(0, 3);

  const emptyCardCount = Math.max(3 - recentTickets.length, 0);

  return (
    <GuestLayout>
      <Head title="Waiting Room" />

      <div className="flex min-h-screen flex-col bg-[#060d1f] text-white">
        <header className="flex min-h-16 items-center justify-between border-b border-slate-800 bg-[#10182a] px-6 md:px-10">
          <div className="flex items-center gap-5">
            <div className="flex items-center gap-2 font-extrabold">
              <span className="h-6 w-6 rounded bg-white" />
              <span>QueueCare AI</span>
            </div>

            <span className="hidden h-6 w-px bg-slate-600 sm:block" />

            <span className="hidden text-sm font-semibold text-slate-300 sm:block">
              Waiting Room
            </span>
          </div>

          <time className="text-sm font-medium text-slate-400">{formatTime(generatedAt)}</time>
        </header>

        <main className="grid flex-1 gap-5 p-5 md:p-8 lg:grid-cols-[minmax(0,1.55fr)_minmax(320px,0.85fr)]">
          <section className="flex min-h-[560px] flex-col items-center justify-center rounded-xl border border-slate-800 bg-[#111c31] px-6 py-10 text-center">
            {currentTicket ? (
              <>
                <div className="flex items-center gap-4 text-sky-400">
                  <BellIcon />

                  <span className="rounded-full border border-sky-400/25 bg-sky-400/15 px-10 py-2 text-sm font-bold">
                    Now Calling
                  </span>
                </div>

                <p className="mt-8 text-[5.5rem] font-black leading-[0.9] tracking-tight text-white sm:text-[7rem] xl:text-[9rem]">
                  {currentTicket.ticket_number}
                </p>

                <div className="mt-10 flex items-center gap-5 rounded-xl border border-slate-700 bg-slate-800/75 px-7 py-5 text-left">
                  <div className="text-sky-400">
                    <MonitorIcon />
                  </div>

                  <div>
                    <p className="text-sm font-bold uppercase tracking-wider text-slate-400">
                      Proceed to
                    </p>

                    <p className="text-3xl font-extrabold sm:text-4xl">
                      {currentTicket.service_window?.name ?? "Service window"}
                    </p>

                    {currentTicket.service_window && (
                      <p className="mt-1 text-sm font-semibold text-sky-400">
                        {currentTicket.service_window.code}
                      </p>
                    )}
                  </div>
                </div>

                <div className="mt-6 flex flex-wrap items-center justify-center gap-x-4 gap-y-2 text-lg text-slate-400">
                  <span>
                    {currentTicket.queue_service.name}
                    {" · "}
                    {currentTicket.queue_service.code}
                  </span>

                  <span className="hidden text-slate-700 sm:inline">•</span>

                  <span>{formatStatus(currentTicket.status)}</span>

                  <span className="hidden text-slate-700 sm:inline">•</span>

                  <span>Called at {formatTime(currentTicket.called_at)}</span>
                </div>
              </>
            ) : (
              <div className="max-w-xl">
                <div className="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-slate-800 text-slate-500">
                  <BellIcon />
                </div>

                <h1 className="mt-6 text-4xl font-extrabold">Waiting for the next ticket</h1>

                <p className="mt-3 text-lg text-slate-500">New calls will appear automatically.</p>
              </div>
            )}
          </section>

          <aside className="flex min-h-[560px] flex-col">
            <div className="mb-5 flex items-center justify-between text-slate-400">
              <div className="flex items-center gap-3">
                <span className="text-sky-400">
                  <ClockIcon />
                </span>

                <h2 className="text-sm font-extrabold uppercase tracking-[0.2em]">
                  Recently Called
                </h2>
              </div>

              <span aria-hidden="true" className="text-xl text-slate-600">
                ◖
              </span>
            </div>

            <div className="space-y-4">
              {recentTickets.map((ticket, index) => (
                <RecentTicketCard key={ticket.id} ticket={ticket} highlighted={index === 0} />
              ))}

              {Array.from({ length: emptyCardCount }).map((_, index) => (
                <div
                  key={`empty-ticket-${index}`}
                  className="flex min-h-28 items-center justify-center rounded-xl border border-dashed border-slate-900 px-6 text-center text-sm text-slate-800"
                >
                  Waiting for upcoming calls...
                </div>
              ))}
            </div>
          </aside>
        </main>

        <div className="bg-sky-500 px-5 py-4 text-center text-base font-black uppercase tracking-[0.14em] text-slate-950 sm:text-xl">
          <span className="text-sky-100">•</span>
          <span className="mx-4">Please stay attentive for your turn</span>
          <span className="text-sky-100">•</span>
        </div>

        <footer className="flex flex-wrap items-center justify-between gap-2 bg-[#10182a] px-6 py-4 text-xs text-slate-600 md:px-10">
          <span>© 2026 QueueCare AI</span>

          <div className="flex gap-6">
            <span>Technical Support</span>
            <span>Privacy</span>
          </div>
        </footer>
      </div>
    </GuestLayout>
  );
}
