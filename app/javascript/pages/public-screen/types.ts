export type QueueServiceRecord = {
  id: number;
  name: string;
  code: string;
};

export type ServiceWindowRecord = {
  id: number;
  name: string;
  code: string;
};

export type AssignedAgentRecord = {
  id: number;
  name: string;
};

export type PublicScreenTicket = {
  id: number;
  ticket_number: string;
  status: "called" | "in_attention" | "attended" | "no_show";
  called_at: string;
  queue_service: QueueServiceRecord;
  service_window: ServiceWindowRecord | null;
  assigned_agent: AssignedAgentRecord | null;
};

export type PublicScreenProps = {
  active_tickets: PublicScreenTicket[];
  recently_called_tickets: PublicScreenTicket[];
  generated_at: string;
};
