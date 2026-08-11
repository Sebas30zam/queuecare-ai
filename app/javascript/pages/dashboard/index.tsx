import { router } from "@inertiajs/react";
import { FormEvent, useState } from "react";

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
  start_date: startDate,
  end_date: endDate,
  summary,
  services,
  hourly_activity: hourlyActivity,
  status_distribution: statusDistribution,
  service_windows: serviceWindows,
  critical_services: criticalServices,
  operational_recommendations: operationalRecommendations,
}: DashboardIndexProps) {
  const [selectedStartDate, setSelectedStartDate] = useState(startDate);
  const [selectedEndDate, setSelectedEndDate] = useState(endDate);
  const hasOperationalData = summary.tickets_created > 0;

  function handleDateSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    router.get(
      "/dashboard",
      {
        start_date: selectedStartDate,
        end_date: selectedEndDate,
      },
      {
        preserveScroll: true,
        preserveState: false,
      },
    );
  }

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
          <form onSubmit={handleDateSubmit} className="flex flex-wrap items-end gap-2">
            <label className="flex flex-col gap-1 text-[10px] font-medium text-slate-600">
              From
              <input
                type="date"
                value={selectedStartDate}
                onChange={(event) => setSelectedStartDate(event.target.value)}
                className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-700 outline-none transition focus:border-blue-400 focus:ring-2 focus:ring-blue-100"
              />
            </label>

            <label className="flex flex-col gap-1 text-[10px] font-medium text-slate-600">
              To
              <input
                type="date"
                value={selectedEndDate}
                onChange={(event) => setSelectedEndDate(event.target.value)}
                className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-700 outline-none transition focus:border-blue-400 focus:ring-2 focus:ring-blue-100"
              />
            </label>

            <button
              type="submit"
              className="rounded-lg bg-slate-950 px-4 py-2 text-xs font-semibold text-white transition hover:bg-slate-800"
            >
              Apply
            </button>

            <span className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-[10px] font-medium text-slate-600">
              All services
            </span>
          </form>

          <span className="text-[10px] text-slate-400">
            {startDate === endDate
              ? `Viewing data for ${formatDate(startDate)}`
              : `Viewing data from ${formatDate(startDate)} to ${formatDate(endDate)}`}
          </span>
        </div>

        {!hasOperationalData && (
          <div className="rounded-xl border border-slate-200 bg-white px-4 py-4 text-sm text-slate-600 shadow-sm">
            No operational data found for the selected period.
          </div>
        )}

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
          <ChartCard
            title="Tickets by service"
            subtitle="Total tickets created for selected period"
          >
            <TicketsByServiceChart services={services} />
          </ChartCard>

          <ChartCard title="Tickets by hour" subtitle="Hourly demand for selected period">
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

          <ChartCard title="Ticket statuses" subtitle="Distribution for selected period">
            <StatusDonut distribution={statusDistribution} />
          </ChartCard>
        </div>

        <div className="grid gap-4 xl:grid-cols-[1fr_1.35fr]">
          <ChartCard
            title="Service window load (%)"
            subtitle="Share of assigned tickets for selected period"
          >
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
