import type { ReactNode } from "react";

type FormSectionProps = {
  eyebrow: string;
  title: string;
  description?: string;
  children: ReactNode;
};

export default function FormSection({ eyebrow, title, description, children }: FormSectionProps) {
  return (
    <section className="border-b border-slate-100 pb-7 last:border-b-0 last:pb-0">
      <div className="mb-5">
        <p className="text-xs font-bold uppercase tracking-[0.18em] text-blue-600">{eyebrow}</p>

        <h2 className="mt-1 text-lg font-bold text-slate-950">{title}</h2>

        {description && (
          <p className="mt-1 max-w-2xl text-sm leading-6 text-slate-500">{description}</p>
        )}
      </div>

      {children}
    </section>
  );
}
