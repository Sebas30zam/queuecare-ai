import type { CSSProperties } from "react";

import type { StatusDistribution } from "../types";

type StatusDonutProps = {
  distribution: StatusDistribution[];
};

const statusConfig: Record<
  string,
  {
    label: string;
    color: string;
  }
> = {
  pending: {
    label: "Pending",
    color: "#f59e0b",
  },
  called: {
    label: "Called",
    color: "#8b5cf6",
  },
  in_attention: {
    label: "In attention",
    color: "#3b82f6",
  },
  attended: {
    label: "Attended",
    color: "#10b981",
  },
  no_show: {
    label: "No-show",
    color: "#ef4444",
  },
  cancelled: {
    label: "Cancelled",
    color: "#94a3b8",
  },
};

export default function StatusDonut({ distribution }: StatusDonutProps) {
  const total = distribution.reduce((sum, item) => sum + item.count, 0);

  let accumulatedPercentage = 0;

  const gradientSegments = distribution.map((item) => {
    const percentage = total === 0 ? 0 : (item.count / total) * 100;
    const start = accumulatedPercentage;
    const end = accumulatedPercentage + percentage;

    accumulatedPercentage = end;

    return `${statusConfig[item.status]?.color ?? "#cbd5e1"} ${start}% ${end}%`;
  });

  const donutStyle: CSSProperties = {
    background: total === 0 ? "#e2e8f0" : `conic-gradient(${gradientSegments.join(", ")})`,
  };

  return (
    <div className="grid items-center gap-5 sm:grid-cols-[150px_1fr]">
      <div className="relative mx-auto h-36 w-36 rounded-full" style={donutStyle}>
        <div className="absolute inset-7 flex flex-col items-center justify-center rounded-full bg-white">
          <span className="text-2xl font-bold text-slate-950">{total}</span>

          <span className="text-[9px] uppercase tracking-wide text-slate-400">Tickets</span>
        </div>
      </div>

      <div className="space-y-2">
        {distribution.map((item) => {
          const config = statusConfig[item.status] ?? {
            label: item.status,
            color: "#cbd5e1",
          };

          return (
            <div key={item.status} className="flex items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <span
                  className="h-2.5 w-2.5 rounded-full"
                  style={{ backgroundColor: config.color }}
                />

                <span className="text-[10px] text-slate-500">{config.label}</span>
              </div>

              <span className="text-[10px] font-semibold text-slate-700">{item.count}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
