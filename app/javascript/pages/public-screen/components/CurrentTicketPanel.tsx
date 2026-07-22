import { BellIcon, MonitorIcon } from "../icons";
import type { PublicScreenTicket } from "../types";
import { formatStatus, formatTime } from "../utils";

type CurrentTicketPanelProps = {
  ticket: PublicScreenTicket | null;
};

export default function CurrentTicketPanel({ ticket }: CurrentTicketPanelProps) {
  return (
    <section className="flex min-h-[560px] flex-col items-center justify-center rounded-xl border border-slate-800 bg-[#111c31] px-6 py-10 text-center">
      {ticket ? (
        <>
          <div className="flex items-center gap-4 text-sky-400">
            <BellIcon />

            <span className="rounded-full border border-sky-400/25 bg-sky-400/15 px-10 py-2 text-sm font-bold">
              Now Calling
            </span>
          </div>

          <p className="mt-8 text-[5.5rem] font-black leading-[0.9] tracking-tight text-white sm:text-[7rem] xl:text-[9rem]">
            {ticket.ticket_number}
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
                {ticket.service_window?.name ?? "Service window"}
              </p>

              {ticket.service_window && (
                <p className="mt-1 text-sm font-semibold text-sky-400">
                  {ticket.service_window.code}
                </p>
              )}
            </div>
          </div>

          <div className="mt-6 flex flex-wrap items-center justify-center gap-x-4 gap-y-2 text-lg text-slate-400">
            <span>
              {ticket.queue_service.name}
              {" · "}
              {ticket.queue_service.code}
            </span>

            <span className="hidden text-slate-700 sm:inline">•</span>

            <span>{formatStatus(ticket.status)}</span>

            <span className="hidden text-slate-700 sm:inline">•</span>

            <span>Called at {formatTime(ticket.called_at)}</span>
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
  );
}
