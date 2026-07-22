import type { ServiceWindowMetrics } from "../types";

type WindowLoadChartProps = {
  windows: ServiceWindowMetrics[];
};

export default function WindowLoadChart({ windows }: WindowLoadChartProps) {
  const visibleWindows = windows.filter((window) => window.tickets_created > 0).slice(0, 5);

  const maxShare = Math.max(...visibleWindows.map((window) => window.ticket_share_percentage), 1);

  return (
    <div className="space-y-4">
      {visibleWindows.map((window) => {
        const normalizedWidth = (window.ticket_share_percentage / maxShare) * 100;

        return (
          <div key={window.id} className="grid grid-cols-[38px_1fr_44px] items-center gap-3">
            <span className="text-[10px] font-semibold text-slate-500">{window.code}</span>

            <div className="h-3.5 overflow-hidden rounded-full bg-slate-100">
              <div
                className="h-full rounded-full bg-emerald-500"
                style={{ width: `${normalizedWidth}%` }}
              />
            </div>

            <span className="text-right text-[9px] font-semibold text-slate-500">
              {window.ticket_share_percentage.toFixed(1)}%
            </span>
          </div>
        );
      })}

      {visibleWindows.length === 0 ? (
        <p className="py-8 text-center text-xs text-slate-400">No service window activity.</p>
      ) : null}
    </div>
  );
}
