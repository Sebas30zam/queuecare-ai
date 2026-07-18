import type { CriticalServiceMetrics, OperationalStatus } from "../types";
import { formatMinutes } from "../utils";

type CriticalServicesTableProps = {
  services: CriticalServiceMetrics[];
};

function operationalStatusPresentation(status: OperationalStatus) {
  const presentations: Record<
    OperationalStatus,
    {
      label: string;
      classes: string;
    }
  > = {
    normal: {
      label: "Normal",
      classes: "bg-emerald-50 text-emerald-700",
    },
    attention: {
      label: "Attention",
      classes: "bg-amber-50 text-amber-700",
    },
    critical: {
      label: "Critical",
      classes: "bg-red-50 text-red-600",
    },
    no_data: {
      label: "No data",
      classes: "bg-slate-100 text-slate-500",
    },
  };

  return presentations[status];
}

export default function CriticalServicesTable({ services }: CriticalServicesTableProps) {
  return (
    <div className="overflow-x-auto">
      <table className="min-w-full">
        <thead>
          <tr className="border-b border-slate-200">
            <th className="px-3 py-2 text-left text-[9px] font-semibold uppercase tracking-wide text-slate-400">
              Servicio
            </th>

            <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
              Tickets
            </th>

            <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
              Espera
            </th>

            <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
              Attention
            </th>

            <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
              Status
            </th>
          </tr>
        </thead>

        <tbody>
          {services.map((service) => {
            const state = operationalStatusPresentation(service.operational_status);

            return (
              <tr key={service.id} className="border-b border-slate-100 last:border-b-0">
                <td className="px-3 py-3">
                  <p className="text-[11px] font-semibold text-slate-800">{service.name}</p>

                  <p className="text-[9px] text-slate-400">{service.code}</p>
                </td>

                <td className="px-3 py-3 text-center text-[10px] text-slate-600">
                  {service.tickets_created}
                </td>

                <td className="px-3 py-3 text-center text-[10px] text-slate-600">
                  {formatMinutes(service.average_wait_time_minutes)}
                </td>

                <td className="px-3 py-3 text-center text-[10px] text-slate-600">
                  {formatMinutes(service.average_attention_time_minutes)}
                </td>

                <td className="px-3 py-3 text-center">
                  <span
                    className={`inline-flex rounded-full px-2 py-1 text-[9px] font-semibold ${state.classes}`}
                  >
                    {state.label}
                  </span>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
