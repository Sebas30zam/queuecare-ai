import type { PublicScreenTicket } from "../types";
import { formatStatus, formatTime } from "../utils";

type RecentTicketCardProps = {
  ticket: PublicScreenTicket;
  highlighted: boolean;
};

export default function RecentTicketCard({ ticket, highlighted }: RecentTicketCardProps) {
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
