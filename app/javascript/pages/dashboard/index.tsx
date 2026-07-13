import type { CSSProperties, ReactNode } from "react"

import AppLayout from "../../layouts/AppLayout"

type DashboardMetrics = {
  tickets_created: number
  tickets_attended: number
  tickets_pending: number
  tickets_no_show: number
  tickets_cancelled: number
  average_wait_time_minutes: number | null
  average_attention_time_minutes: number | null
  average_satisfaction_rating: number | null
  survey_response_count: number
}

type ServiceMetrics = DashboardMetrics & {
  id: number
  name: string
  code: string
}

type OperationalStatus =
  | "normal"
  | "attention"
  | "critical"
  | "no_data"

type CriticalServiceMetrics = ServiceMetrics & {
  operational_status: OperationalStatus
}

type OperationalInsights = {
  peak_hour: HourlyActivity | null
  highest_wait_service: {
    id: number
    name: string
    code: string
    average_wait_time_minutes: number
  } | null
}

type HourlyActivity = {
  hour: number
  label: string
  tickets_created: number
}

type StatusDistribution = {
  status: string
  count: number
}

type ServiceWindowMetrics = {
  id: number
  name: string
  code: string
  tickets_created: number
  ticket_share_percentage: number
  queue_service: {
    id: number
    name: string
    code: string
  }
}

type DashboardIndexProps = {
  date: string
  summary: DashboardMetrics
  services: ServiceMetrics[]
  hourly_activity: HourlyActivity[]
  status_distribution: StatusDistribution[]
  service_windows: ServiceWindowMetrics[]
  critical_services: CriticalServiceMetrics[]
  insights: OperationalInsights
}

type MetricCardProps = {
  title: string
  value: string
  detail: string
  icon: ReactNode
  iconClasses: string
}

const statusConfig: Record<
  string,
  {
    label: string
    color: string
  }
> = {
  pending: {
    label: "Pending",
    color: "#f59e0b",
  },
  called: {
    label: "Called",
    color: "#8b5cf6",
  },
  in_attention: {
    label: "In attention",
    color: "#3b82f6",
  },
  attended: {
    label: "Attended",
    color: "#10b981",
  },
  no_show: {
    label: "No-show",
    color: "#ef4444",
  },
  cancelled: {
    label: "Cancelled",
    color: "#94a3b8",
  },
}

function formatDate(date: string) {
  const parsedDate = new Date(`${date}T00:00:00`)

  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(parsedDate)
}

function formatMinutes(value: number | null) {
  return value === null ? "No data" : `${value.toFixed(2)} min`
}

function formatRating(value: number | null) {
  return value === null ? "No data" : `${value.toFixed(2)} / 5`
}

function operationalStatusPresentation(status: OperationalStatus) {
  const presentations: Record<
    OperationalStatus,
    {
      label: string
      classes: string
    }
  > = {
    normal: {
      label: "Normal",
      classes: "bg-emerald-50 text-emerald-700",
    },
    attention: {
      label: "Attention",
      classes: "bg-amber-50 text-amber-700",
    },
    critical: {
      label: "Critical",
      classes: "bg-red-50 text-red-600",
    },
    no_data: {
      label: "No data",
      classes: "bg-slate-100 text-slate-500",
    },
  }

  return presentations[status]
}

function MetricCard({
  title,
  value,
  detail,
  icon,
  iconClasses,
}: MetricCardProps) {
  return (
    <article className="rounded-xl border border-slate-200 bg-white px-4 py-3.5 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[11px] font-medium text-slate-500">
            {title}
          </p>

          <p className="mt-2 text-[22px] font-bold leading-none tracking-tight text-slate-950">
            {value}
          </p>

          <p className="mt-2 text-[10px] text-slate-400">
            {detail}
          </p>
        </div>

        <span
          className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${iconClasses}`}
        >
          {icon}
        </span>
      </div>
    </article>
  )
}

function ChartCard({
  title,
  subtitle,
  children,
  className = "",
}: {
  title: string
  subtitle?: string
  children: ReactNode
  className?: string
}) {
  return (
    <article
      className={`rounded-xl border border-slate-200 bg-white p-4 shadow-sm ${className}`}
    >
      <div className="mb-4">
        <h2 className="text-xs font-semibold text-slate-900">
          {title}
        </h2>

        {subtitle ? (
          <p className="mt-1 text-[10px] text-slate-400">
            {subtitle}
          </p>
        ) : null}
      </div>

      {children}
    </article>
  )
}

function TicketsByServiceChart({
  services,
}: {
  services: ServiceMetrics[]
}) {
  const hasActivity = services.some(
    (service) => service.tickets_created > 0,
  )

  if (!hasActivity) {
    return (
      <div className="flex h-52 items-center justify-center text-xs text-slate-400">
        No tickets created today.
      </div>
    )
  }

  const maxValue = Math.max(
    ...services.map((service) => service.tickets_created),
    1,
  )

  return (
    <div className="flex h-52 items-end gap-3 border-b border-l border-slate-200 px-3 pb-6 pt-3">
      {services.map((service) => {
        const height = (service.tickets_created / maxValue) * 100

        return (
          <div
            key={service.id}
            className="flex h-full min-w-0 flex-1 flex-col items-center justify-end"
          >
            <span className="mb-1 text-[9px] font-semibold text-slate-500">
              {service.tickets_created}
            </span>

            <div className="flex h-full w-full items-end justify-center">
              <div
                className="w-full max-w-9 rounded-t-md bg-blue-500 transition-all"
                style={{ height: `${Math.max(height, 4)}%` }}
              />
            </div>

            <span className="absolute mt-[218px] text-[9px] font-medium text-slate-500">
              {service.code}
            </span>
          </div>
        )
      })}
    </div>
  )
}

function HourlyLineChart({
  activity,
}: {
  activity: HourlyActivity[]
}) {
  const visibleActivity = activity

  if (visibleActivity.length === 0) {
    return (
      <div className="flex h-52 items-center justify-center text-xs text-slate-400">
        No hourly activity today.
      </div>
    )
  }

  const width = 620
  const height = 205
  const paddingLeft = 34
  const paddingRight = 16
  const paddingTop = 12
  const paddingBottom = 28
  const chartWidth = width - paddingLeft - paddingRight
  const chartHeight = height - paddingTop - paddingBottom
  const maxValue = Math.max(
    ...visibleActivity.map((item) => item.tickets_created),
    1,
  )

  const points = visibleActivity.map((item, index) => {
    const x =
      paddingLeft +
      (index / Math.max(visibleActivity.length - 1, 1)) * chartWidth

    const y =
      paddingTop +
      chartHeight -
      (item.tickets_created / maxValue) * chartHeight

    return {
      ...item,
      x,
      y,
    }
  })

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      className="h-52 w-full"
      role="img"
      aria-label="Tickets created por hora"
    >
      {[0, 0.25, 0.5, 0.75, 1].map((percentage) => {
        const y = paddingTop + chartHeight * percentage

        return (
          <line
            key={percentage}
            x1={paddingLeft}
            y1={y}
            x2={width - paddingRight}
            y2={y}
            stroke="#e2e8f0"
            strokeWidth="1"
          />
        )
      })}

      <polygon
        points={[
          `${points[0]?.x ?? paddingLeft},${paddingTop + chartHeight}`,
          ...points.map((point) => `${point.x},${point.y}`),
          `${points[points.length - 1]?.x ?? width - paddingRight},${paddingTop + chartHeight}`,
        ].join(" ")}
        fill="rgba(59, 130, 246, 0.10)"
      />

      <polyline
        points={points.map((point) => `${point.x},${point.y}`).join(" ")}
        fill="none"
        stroke="#3b82f6"
        strokeWidth="3"
        strokeLinejoin="round"
        strokeLinecap="round"
      />

      {points.map((point) => (
        <g key={point.hour}>
          <circle
            cx={point.x}
            cy={point.y}
            r="4"
            fill="#ffffff"
            stroke="#3b82f6"
            strokeWidth="2"
          />

          <text
            x={point.x}
            y={height - 8}
            textAnchor="middle"
            fontSize="9"
            fill="#64748b"
          >
            {point.label}
          </text>
        </g>
      ))}
    </svg>
  )
}

function AverageWaitChart({
  services,
}: {
  services: ServiceMetrics[]
}) {
  const servicesWithWaitData = services.filter(
    (service) => service.average_wait_time_minutes !== null,
  )

  if (servicesWithWaitData.length === 0) {
    return (
      <div className="flex min-h-44 items-center justify-center text-xs text-slate-400">
        No wait times recorded today.
      </div>
    )
  }

  const maxValue = Math.max(
    ...servicesWithWaitData.map(
      (service) => service.average_wait_time_minutes ?? 0,
    ),
    1,
  )

  return (
    <div className="space-y-3">
      {servicesWithWaitData.map((service) => {
        const value = service.average_wait_time_minutes ?? 0
        const width = (value / maxValue) * 100

        return (
          <div
            key={service.id}
            className="grid grid-cols-[40px_1fr_55px] items-center gap-2"
          >
            <span className="text-[10px] font-medium text-slate-500">
              {service.code}
            </span>

            <div className="h-3 overflow-hidden rounded-sm bg-slate-100">
              <div
                className="h-full rounded-sm bg-violet-500"
                style={{ width: `${width}%` }}
              />
            </div>

            <span className="text-right text-[9px] font-medium text-slate-500">
              {value > 0 ? `${value.toFixed(1)} min` : "—"}
            </span>
          </div>
        )
      })}
    </div>
  )
}

function StatusDonut({
  distribution,
}: {
  distribution: StatusDistribution[]
}) {
  const total = distribution.reduce(
    (sum, item) => sum + item.count,
    0,
  )

  let accumulatedPercentage = 0

  const gradientSegments = distribution.map((item) => {
    const percentage =
      total === 0 ? 0 : (item.count / total) * 100

    const start = accumulatedPercentage
    const end = accumulatedPercentage + percentage
    accumulatedPercentage = end

    return `${statusConfig[item.status]?.color ?? "#cbd5e1"} ${start}% ${end}%`
  })

  const donutStyle: CSSProperties = {
    background:
      total === 0
        ? "#e2e8f0"
        : `conic-gradient(${gradientSegments.join(", ")})`,
  }

  return (
    <div className="grid items-center gap-5 sm:grid-cols-[150px_1fr]">
      <div
        className="relative mx-auto h-36 w-36 rounded-full"
        style={donutStyle}
      >
        <div className="absolute inset-7 flex flex-col items-center justify-center rounded-full bg-white">
          <span className="text-2xl font-bold text-slate-950">
            {total}
          </span>

          <span className="text-[9px] uppercase tracking-wide text-slate-400">
            Tickets
          </span>
        </div>
      </div>

      <div className="space-y-2">
        {distribution.map((item) => {
          const config =
            statusConfig[item.status] ?? {
              label: item.status,
              color: "#cbd5e1",
            }

          return (
            <div
              key={item.status}
              className="flex items-center justify-between gap-3"
            >
              <div className="flex items-center gap-2">
                <span
                  className="h-2.5 w-2.5 rounded-full"
                  style={{ backgroundColor: config.color }}
                />

                <span className="text-[10px] text-slate-500">
                  {config.label}
                </span>
              </div>

              <span className="text-[10px] font-semibold text-slate-700">
                {item.count}
              </span>
            </div>
          )
        })}
      </div>
    </div>
  )
}

function WindowLoadChart({
  windows,
}: {
  windows: ServiceWindowMetrics[]
}) {
  const visibleWindows = windows
    .filter((window) => window.tickets_created > 0)
    .slice(0, 5)

  const maxShare = Math.max(
    ...visibleWindows.map(
      (window) => window.ticket_share_percentage,
    ),
    1,
  )

  return (
    <div className="space-y-4">
      {visibleWindows.map((window) => {
        const normalizedWidth =
          (window.ticket_share_percentage / maxShare) * 100

        return (
          <div
            key={window.id}
            className="grid grid-cols-[38px_1fr_44px] items-center gap-3"
          >
            <span className="text-[10px] font-semibold text-slate-500">
              {window.code}
            </span>

            <div className="h-3.5 overflow-hidden rounded-full bg-slate-100">
              <div
                className="h-full rounded-full bg-emerald-500"
                style={{ width: `${normalizedWidth}%` }}
              />
            </div>

            <span className="text-right text-[9px] font-semibold text-slate-500">
              {window.ticket_share_percentage.toFixed(1)}%
            </span>
          </div>
        )
      })}

      {visibleWindows.length === 0 ? (
        <p className="py-8 text-center text-xs text-slate-400">
          No service window activity.
        </p>
      ) : null}
    </div>
  )
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
          <h1 className="text-lg font-bold tracking-tight text-slate-950">
            General Overview
          </h1>

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

          <span className="text-[10px] text-slate-400">
            Updated with today's data
          </span>
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
              summary.survey_response_count === 1
                ? "response received"
                : "responses received"
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
          <ChartCard
            title="Tickets by service"
            subtitle="Total tickets created today"
          >
            <TicketsByServiceChart services={services} />
          </ChartCard>

          <ChartCard
            title="Tickets by hour"
            subtitle="Hourly demand throughout today's activity"
          >
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

          <ChartCard
            title="Ticket statuses"
            subtitle="Distribution of tickets created today"
          >
            <StatusDonut distribution={statusDistribution} />
          </ChartCard>
        </div>

        <div className="grid gap-4 xl:grid-cols-[1fr_1.35fr]">
          <ChartCard
            title="Service window load (%)"
            subtitle="Share of tickets assigned today"
          >
            <WindowLoadChart windows={serviceWindows} />
          </ChartCard>

          <ChartCard
            title="Critical Services"
            subtitle="Services ranked by highest average wait time"
          >
            <div className="overflow-x-auto">
              <table className="min-w-full">
                <thead>
                  <tr className="border-b border-slate-200">
                    <th className="px-3 py-2 text-left text-[9px] font-semibold uppercase tracking-wide text-slate-400">
                      Servicio
                    </th>
                    <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
                      Tickets
                    </th>
                    <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
                      Espera
                    </th>
                    <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
                      Attention
                    </th>
                    <th className="px-3 py-2 text-center text-[9px] font-semibold uppercase tracking-wide text-slate-400">
                      Status
                    </th>
                  </tr>
                </thead>

                <tbody>
                  {criticalServices.map((service) => {
                    const state = operationalStatusPresentation(
                      service.operational_status,
                    )

                    return (
                      <tr
                        key={service.id}
                        className="border-b border-slate-100 last:border-b-0"
                      >
                        <td className="px-3 py-3">
                          <p className="text-[11px] font-semibold text-slate-800">
                            {service.name}
                          </p>

                          <p className="text-[9px] text-slate-400">
                            {service.code}
                          </p>
                        </td>

                        <td className="px-3 py-3 text-center text-[10px] text-slate-600">
                          {service.tickets_created}
                        </td>

                        <td className="px-3 py-3 text-center text-[10px] text-slate-600">
                          {formatMinutes(
                            service.average_wait_time_minutes,
                          )}
                        </td>

                        <td className="px-3 py-3 text-center text-[10px] text-slate-600">
                          {formatMinutes(
                            service.average_attention_time_minutes,
                          )}
                        </td>

                        <td className="px-3 py-3 text-center">
                          <span
                            className={`inline-flex rounded-full px-2 py-1 text-[9px] font-semibold ${state.classes}`}
                          >
                            {state.label}
                          </span>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          </ChartCard>
        </div>
      </section>
    </AppLayout>
  )
}
