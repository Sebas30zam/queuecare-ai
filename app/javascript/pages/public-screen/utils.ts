import type { PublicScreenTicket } from "./types";

export function formatTime(dateTime: string) {
  return new Date(dateTime).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatStatus(status: PublicScreenTicket["status"]) {
  const statusLabels: Record<PublicScreenTicket["status"], string> = {
    called: "Called",
    in_attention: "In attention",
    attended: "Attended",
    no_show: "No-show",
  };

  return statusLabels[status];
}
