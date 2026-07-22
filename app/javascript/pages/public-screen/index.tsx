import { Head, router } from "@inertiajs/react";
import { useEffect } from "react";

import GuestLayout from "../../layouts/GuestLayout";
import AttentionBanner from "./components/AttentionBanner";
import CurrentTicketPanel from "./components/CurrentTicketPanel";
import PublicScreenFooter from "./components/PublicScreenFooter";
import PublicScreenHeader from "./components/PublicScreenHeader";
import RecentTicketsPanel from "./components/RecentTicketsPanel";
import type { PublicScreenProps } from "./types";

export default function PublicScreen({
  active_tickets: activeTickets,
  recently_called_tickets: recentlyCalledTickets,
  generated_at: generatedAt,
}: PublicScreenProps) {
  useEffect(() => {
    const intervalId = window.setInterval(() => {
      router.reload({
        only: ["active_tickets", "recently_called_tickets", "generated_at"],
      });
    }, 5_000);

    return () => window.clearInterval(intervalId);
  }, []);

  const currentTicket = activeTickets[0] ?? null;

  const recentTickets = recentlyCalledTickets
    .filter((ticket) => ticket.id !== currentTicket?.id)
    .slice(0, 3);

  const emptyCardCount = Math.max(3 - recentTickets.length, 0);

  return (
    <GuestLayout>
      <Head title="Waiting Room" />

      <div className="flex min-h-screen flex-col bg-[#060d1f] text-white">
        <PublicScreenHeader generatedAt={generatedAt} />

        <main className="grid flex-1 gap-5 p-5 md:p-8 lg:grid-cols-[minmax(0,1.55fr)_minmax(320px,0.85fr)]">
          <CurrentTicketPanel ticket={currentTicket} />

          <RecentTicketsPanel tickets={recentTickets} emptyCardCount={emptyCardCount} />
        </main>

        <AttentionBanner />

        <PublicScreenFooter />
      </div>
    </GuestLayout>
  );
}
