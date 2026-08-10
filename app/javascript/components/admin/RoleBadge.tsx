type RoleBadgeProps = {
  role: string;
};

const roleClasses: Record<string, string> = {
  admin: "bg-violet-50 text-violet-700 ring-violet-600/10",
  supervisor: "bg-blue-50 text-blue-700 ring-blue-600/10",
  receptionist: "bg-amber-50 text-amber-700 ring-amber-600/10",
  agent: "bg-cyan-50 text-cyan-700 ring-cyan-600/10",
};

export default function RoleBadge({ role }: RoleBadgeProps) {
  const label = role.charAt(0).toUpperCase() + role.slice(1);

  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ring-1 ring-inset ${
        roleClasses[role] ?? "bg-slate-100 text-slate-600 ring-slate-500/10"
      }`}
    >
      {label}
    </span>
  );
}
