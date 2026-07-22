import { ClockIcon } from "../icons";
import type { PublicScreenTicket } from "../types";
import RecentTicketCard from "./RecentTicketCard";

type RecentTicketsPanelProps = {
  tickets: PublicScreenTicket[];
  emptyCardCount: number;
};

export default function RecentTicketsPanel({ tickets, emptyCardCount }: RecentTicketsPanelProps) {
  return (
    <aside className="flex min-h-[560px] flex-col">
      <div className="mb-5 flex items-center justify-between text-slate-400">
        <div className="flex items-center gap-3">
          <span className="text-sky-400">
            <ClockIcon />
          </span>

          <h2 className="text-sm font-extrabold uppercase tracking-[0.2em]">Recently Called</h2>
        </div>

        <span aria-hidden="true" className="text-xl text-slate-600">
          ◖
        </span>
      </div>

      <div className="space-y-4">
        {tickets.map((ticket, index) => (
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
  );
}
