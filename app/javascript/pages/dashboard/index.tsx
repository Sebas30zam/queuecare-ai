import AppLayout from "../../layouts/AppLayout";
import AverageWaitChart from "./components/AverageWaitChart";
import ChartCard from "./components/ChartCard";
import CriticalServicesTable from "./components/CriticalServicesTable";
import HourlyLineChart from "./components/HourlyLineChart";
import MetricCard from "./components/MetricCard";
import OperationalRecommendationCards from "./components/OperationalRecommendationCards";

import StatusDonut from "./components/StatusDonut";
import TicketsByServiceChart from "./components/TicketsByServiceChart";
import WindowLoadChart from "./components/WindowLoadChart";
import type { DashboardIndexProps } from "./types";
import { formatDate, formatMinutes } from "./utils";

function formatRating(value: number | null) {
  return value === null ? "No data" : `${value.toFixed(2)} / 5`;
}

export default function DashboardIndex({
  date,
  summary,
  services,
  hourly_activity: hourlyActivity,
  status_distribution: statusDistribution,
  service_windows: serviceWindows,
  critical_services: criticalServices,
  operational_recommendations: operationalRecommendations,
}: DashboardIndexProps) {
  return (
    <AppLayout>
      <section className="mx-auto max-w-[1500px] space-y-4">
        <div>
          <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
            Dashboard
          </span>

          <h1 className="mt-2 text-2xl font-bold tracking-tight text-slate-950">
            General Overview
          </h1>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white px-4 py-3 shadow-sm">
          <div className="flex flex-wrap items-center gap-2">
            <span className="rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-[10px] font-medium text-slate-600">
              Today
            </span>

            <span className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-[10px] font-medium text-slate-600">
              {formatDate(date)}
            </span>

            <span className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-[10px] font-medium text-slate-600">
              All services
            </span>
          </div>

          <span className="text-[10px] text-slate-400">Updated with today's data</span>
        </div>

        <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <MetricCard
            title="Tickets created"
            value={summary.tickets_created.toString()}
            detail={`${summary.tickets_pending} currently pending`}
            iconClasses="bg-blue-50 text-blue-600"
            icon={
              <svg
                viewBox="0 0 24 24"
                className="h-4 w-4"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M6 3h12v18H6z" />
                <path d="M9 7h6M9 11h6M9 15h4" />
              </svg>
            }
          />

          <MetricCard
            title="Average wait time"
            value={formatMinutes(summary.average_wait_time_minutes)}
            detail="From creation to call"
            iconClasses="bg-violet-50 text-violet-600"
            icon={
              <svg
                viewBox="0 0 24 24"
                className="h-4 w-4"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <circle cx="12" cy="12" r="9" />
                <path d="M12 7v5l3 2" />
              </svg>
            }
          />

          <MetricCard
            title="Average attention time"
            value={formatMinutes(summary.average_attention_time_minutes)}
            detail={`${summary.tickets_attended} tickets attended`}
            iconClasses="bg-emerald-50 text-emerald-600"
            icon={
              <svg
                viewBox="0 0 24 24"
                className="h-4 w-4"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M4 12l5 5L20 6" />
              </svg>
            }
          />

          <MetricCard
            title="Average satisfaction"
            value={formatRating(summary.average_satisfaction_rating)}
            detail={`${summary.survey_response_count} ${
              summary.survey_response_count === 1 ? "response received" : "responses received"
            }`}
            iconClasses="bg-amber-50 text-amber-600"
            icon={
              <svg
                viewBox="0 0 24 24"
                className="h-4 w-4"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
              >
                <path d="M12 3l2.7 5.5 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1-4.4-4.3 6.1-.9z" />
              </svg>
            }
          />
        </div>

        <OperationalRecommendationCards operationalRecommendations={operationalRecommendations} />

        <div className="grid gap-4 xl:grid-cols-2">
          <ChartCard title="Tickets by service" subtitle="Total tickets created today">
            <TicketsByServiceChart services={services} />
          </ChartCard>

          <ChartCard title="Tickets by hour" subtitle="Hourly demand throughout today's activity">
            <HourlyLineChart activity={hourlyActivity} />
          </ChartCard>
        </div>

        <div className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
          <ChartCard
            title="Average wait time by service"
            subtitle="Average wait before being called"
          >
            <AverageWaitChart services={services} />
          </ChartCard>

          <ChartCard title="Ticket statuses" subtitle="Distribution of tickets created today">
            <StatusDonut distribution={statusDistribution} />
          </ChartCard>
        </div>

        <div className="grid gap-4 xl:grid-cols-[1fr_1.35fr]">
          <ChartCard title="Service window load (%)" subtitle="Share of tickets assigned today">
            <WindowLoadChart windows={serviceWindows} />
          </ChartCard>

          <ChartCard
            title="Critical Services"
            subtitle="Services ranked by highest average wait time"
          >
            <CriticalServicesTable services={criticalServices} />
          </ChartCard>
        </div>
      </section>
    </AppLayout>
  );
}
