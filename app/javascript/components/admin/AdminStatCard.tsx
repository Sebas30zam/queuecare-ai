type AdminStatCardProps = {
  label: string;
  value: number | string;
  helper?: string;
};

export default function AdminStatCard({ label, value, helper }: AdminStatCardProps) {
  return (
    <article className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <p className="text-xs font-semibold uppercase tracking-[0.16em] text-slate-400">{label}</p>

      <div className="mt-3 flex items-end justify-between gap-4">
        <p className="text-3xl font-bold tracking-tight text-slate-950">{value}</p>

        {helper && <p className="pb-1 text-right text-xs font-medium text-slate-500">{helper}</p>}
      </div>
    </article>
  );
}
