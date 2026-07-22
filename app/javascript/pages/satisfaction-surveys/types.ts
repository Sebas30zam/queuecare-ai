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

export type SurveyTicket = {
  ticket_number: string;
  status: string;
  queue_service: QueueServiceRecord;
  service_window: ServiceWindowRecord | null;
};

export type SatisfactionSurveyProps = {
  ticket: SurveyTicket;
  submitted: boolean;
  errors: string[];
};

export type SurveyFormData = {
  rating: number | null;
  comment: string;
};
