import type { ServiceMetrics } from "../types";

type AverageWaitChartProps = {
  services: ServiceMetrics[];
};

export default function AverageWaitChart({ services }: AverageWaitChartProps) {
  const servicesWithWaitData = services.filter(
    (service) => service.average_wait_time_minutes !== null,
  );

  if (servicesWithWaitData.length === 0) {
    return (
      <div className="flex min-h-44 items-center justify-center text-xs text-slate-400">
        No wait times recorded today.
      </div>
    );
  }

  const maxValue = Math.max(
    ...servicesWithWaitData.map((service) => service.average_wait_time_minutes ?? 0),
    1,
  );

  return (
    <div className="space-y-3">
      {servicesWithWaitData.map((service) => {
        const value = service.average_wait_time_minutes ?? 0;
        const width = (value / maxValue) * 100;

        return (
          <div key={service.id} className="grid grid-cols-[40px_1fr_55px] items-center gap-2">
            <span className="text-[10px] font-medium text-slate-500">{service.code}</span>

            <div className="h-3 overflow-hidden rounded-sm bg-slate-100">
              <div className="h-full rounded-sm bg-violet-500" style={{ width: `${width}%` }} />
            </div>

            <span className="text-right text-[9px] font-medium text-slate-500">
              {value > 0 ? `${value.toFixed(1)} min` : "—"}
            </span>
          </div>
        );
      })}
    </div>
  );
}
