import type { ReactNode } from "react";

type ChartCardProps = {
  title: string;
  subtitle?: string;
  children: ReactNode;
  className?: string;
};

export default function ChartCard({ title, subtitle, children, className = "" }: ChartCardProps) {
  return (
    <article className={`rounded-xl border border-slate-200 bg-white p-4 shadow-sm ${className}`}>
      <div className="mb-4">
        <h2 className="text-xs font-semibold text-slate-900">{title}</h2>

        {subtitle ? <p className="mt-1 text-[10px] text-slate-400">{subtitle}</p> : null}
      </div>

      {children}
    </article>
  );
}
