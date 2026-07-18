import AppLayout from "../../layouts/AppLayout";
import AverageWaitChart from "./components/AverageWaitChart";
import ChartCard from "./components/ChartCard";
import CriticalServicesTable from "./components/CriticalServicesTable";
import HourlyLineChart from "./components/HourlyLineChart";
import MetricCard from "./components/MetricCard";
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
  insights,
}: DashboardIndexProps) {
  return (
    <AppLayout>
      <section className="mx-auto max-w-[1500px] space-y-4">
        <div>
          <h1 className="text-lg font-bold tracking-tight text-slate-950">General Overview</h1>

          <p className="mt-1 text-[11px] text-slate-500">
            Operational monitoring of today's queues and services.
          </p>
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

        <div className="grid gap-3 lg:grid-cols-2">
          <article className="rounded-xl border border-blue-100 bg-blue-50 px-4 py-3">
            <p className="text-[10px] font-semibold uppercase tracking-wide text-blue-600">
              Highest wait time
            </p>

            <p className="mt-1 text-xs font-semibold text-slate-900">
              {insights.highest_wait_service
                ? `${insights.highest_wait_service.name}: ${formatMinutes(
                    insights.highest_wait_service.average_wait_time_minutes,
                  )}`
                : "No hay datos suficientes"}
            </p>

            <p className="mt-1 text-[10px] text-slate-500">
              Service requiring the most operational attention today.
            </p>
          </article>

          <article className="rounded-xl border border-amber-100 bg-amber-50 px-4 py-3">
            <p className="text-[10px] font-semibold uppercase tracking-wide text-amber-700">
              Peak demand hour
            </p>

            <p className="mt-1 text-xs font-semibold text-slate-900">
              {insights.peak_hour
                ? `${insights.peak_hour.label}: ${insights.peak_hour.tickets_created} tickets`
                : "No hay datos suficientes"}
            </p>

            <p className="mt-1 text-[10px] text-slate-500">
              Time slot with the most tickets created today.
            </p>
          </article>
        </div>

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
