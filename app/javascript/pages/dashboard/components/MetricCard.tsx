import type { MetricCardProps } from "../types";

export default function MetricCard({ title, value, detail, icon, iconClasses }: MetricCardProps) {
  return (
    <article className="rounded-xl border border-slate-200 bg-white px-4 py-3.5 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[11px] font-medium text-slate-500">{title}</p>

          <p className="mt-2 text-[22px] font-bold leading-none tracking-tight text-slate-950">
            {value}
          </p>

          <p className="mt-2 text-[10px] text-slate-400">{detail}</p>
        </div>

        <span
          className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${iconClasses}`}
        >
          {icon}
        </span>
      </div>
    </article>
  );
}
