import type { ServiceMetrics } from "../types";

type TicketsByServiceChartProps = {
  services: ServiceMetrics[];
};

export default function TicketsByServiceChart({ services }: TicketsByServiceChartProps) {
  const hasActivity = services.some((service) => service.tickets_created > 0);

  if (!hasActivity) {
    return (
      <div className="flex h-52 items-center justify-center text-xs text-slate-400">
        No tickets created today.
      </div>
    );
  }

  const maxValue = Math.max(...services.map((service) => service.tickets_created), 1);

  return (
    <div className="flex h-52 items-end gap-3 border-b border-l border-slate-200 px-3 pb-6 pt-3">
      {services.map((service) => {
        const height = (service.tickets_created / maxValue) * 100;

        return (
          <div
            key={service.id}
            className="flex h-full min-w-0 flex-1 flex-col items-center justify-end"
          >
            <span className="mb-1 text-[9px] font-semibold text-slate-500">
              {service.tickets_created}
            </span>

            <div className="flex h-full w-full items-end justify-center">
              <div
                className="w-full max-w-9 rounded-t-md bg-blue-500 transition-all"
                style={{ height: `${Math.max(height, 4)}%` }}
              />
            </div>

            <span className="absolute mt-[218px] text-[9px] font-medium text-slate-500">
              {service.code}
            </span>
          </div>
        );
      })}
    </div>
  );
}
