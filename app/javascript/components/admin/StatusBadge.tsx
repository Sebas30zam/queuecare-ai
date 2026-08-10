type StatusBadgeProps = {
  active: boolean;
};

export default function StatusBadge({ active }: StatusBadgeProps) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-semibold ${
        active
          ? "bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-600/10"
          : "bg-slate-100 text-slate-600 ring-1 ring-inset ring-slate-500/10"
      }`}
    >
      <span className={`h-1.5 w-1.5 rounded-full ${active ? "bg-emerald-500" : "bg-slate-400"}`} />

      {active ? "Active" : "Inactive"}
    </span>
  );
}
