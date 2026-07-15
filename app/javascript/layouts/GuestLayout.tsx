import type { ReactNode } from "react";

type GuestLayoutProps = {
  children: ReactNode;
};

export default function GuestLayout({ children }: GuestLayoutProps) {
  return <div className="min-h-screen bg-white text-slate-950">{children}</div>;
}
