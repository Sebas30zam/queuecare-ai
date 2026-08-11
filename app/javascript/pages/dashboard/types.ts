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

export type OperationalRecommendationsStatus = "ready" | "insufficient_data";

export type DetailedRecommendationCode =
  | "high_wait_time"
  | "high_attention_time"
  | "high_no_show_rate"
  | "saturated_service"
  | "peak_demand_hour"
  | "uneven_service_window_load";

export type RecommendationEvidence = {
  metric_name: string;
  observed_value: number;
  threshold_value: number;
  context: "historical_operational_profile";
  hour?: number;
  service_name?: string;
  service_code?: string;
  service_window_name?: string;
  service_window_code?: string;
  queue_service_name?: string;
  queue_service_code?: string;
};

export type DetailedOperationalRecommendation = {
  code: DetailedRecommendationCode;
  title: string;
  description: string;
  severity: "warning";
  suggested_action: string;
  evidence: RecommendationEvidence;
};

export type PriorityOperationalRecommendation =
  | {
      code: "holiday_operational_review" | "adjacent_holiday_operational_review";
      priority: "attention";
    }
  | {
      code: "insufficient_historical_data";
      priority: "information";
    };

export type OperationalRecommendation =
  DetailedOperationalRecommendation | PriorityOperationalRecommendation;

export type NextHolidayAlert = {
  date: string;
  names: string[];
  days_away: number;
  recommended_staffing_date: string;
  historical_data_available: boolean;
  demand_change_percentage: number | null;
  historical_sample: {
    post_holiday_days: number;
    baseline_days: number;
  };
};

export type OperationalRecommendations = {
  status: OperationalRecommendationsStatus;
  recommendations: OperationalRecommendation[];
  next_holiday_alert: NextHolidayAlert | null;
};

export type DashboardIndexProps = {
  start_date: string;
  end_date: string;
  summary: DashboardMetrics;
  services: ServiceMetrics[];
  hourly_activity: HourlyActivity[];
  status_distribution: StatusDistribution[];
  service_windows: ServiceWindowMetrics[];
  critical_services: CriticalServiceMetrics[];
  insights: OperationalInsights;
  operational_recommendations: OperationalRecommendations;
};

export type MetricCardProps = {
  title: string;
  value: string;
  detail: string;
  icon: ReactNode;
  iconClasses: string;
};
