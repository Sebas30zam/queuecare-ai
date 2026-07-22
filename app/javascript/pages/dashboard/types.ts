import type { ReactNode } from "react";

export type DashboardMetrics = {
  tickets_created: number;
  tickets_attended: number;
  tickets_pending: number;
  tickets_no_show: number;
  tickets_cancelled: number;
  average_wait_time_minutes: number | null;
  average_attention_time_minutes: number | null;
  average_satisfaction_rating: number | null;
  survey_response_count: number;
};

export type ServiceMetrics = DashboardMetrics & {
  id: number;
  name: string;
  code: string;
};

export type OperationalStatus = "normal" | "attention" | "critical" | "no_data";

export type CriticalServiceMetrics = ServiceMetrics & {
  operational_status: OperationalStatus;
};

export type HourlyActivity = {
  hour: number;
  label: string;
  tickets_created: number;
};

export type OperationalInsights = {
  peak_hour: HourlyActivity | null;
  highest_wait_service: {
    id: number;
    name: string;
    code: string;
    average_wait_time_minutes: number;
  } | null;
};

export type StatusDistribution = {
  status: string;
  count: number;
};

export type ServiceWindowMetrics = {
  id: number;
  name: string;
  code: string;
  tickets_created: number;
  ticket_share_percentage: number;
  queue_service: {
    id: number;
    name: string;
    code: string;
  };
};

export type DashboardIndexProps = {
  date: string;
  summary: DashboardMetrics;
  services: ServiceMetrics[];
  hourly_activity: HourlyActivity[];
  status_distribution: StatusDistribution[];
  service_windows: ServiceWindowMetrics[];
  critical_services: CriticalServiceMetrics[];
  insights: OperationalInsights;
};

export type MetricCardProps = {
  title: string;
  value: string;
  detail: string;
  icon: ReactNode;
  iconClasses: string;
};
