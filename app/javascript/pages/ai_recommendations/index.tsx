import AppLayout from "../../layouts/AppLayout";
import type {
  DetailedOperationalRecommendation,
  OperationalRecommendation,
  OperationalRecommendations,
} from "../dashboard/types";

type AiRecommendationsIndexProps = {
  date: string;
  operational_recommendations: OperationalRecommendations;
};

function isDetailedRecommendation(
  recommendation: OperationalRecommendation,
): recommendation is DetailedOperationalRecommendation {
  return "title" in recommendation;
}

function formatDate(value: string) {
  const [year, month, day] = value.split("-").map(Number);

  return new Intl.DateTimeFormat("en-US", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(year, month - 1, day));
}

function recommendationCategory(code: string) {
  const categories: Record<string, string> = {
    high_wait_time: "WAIT TIMES",
    high_attention_time: "SERVICE TIMES",
    high_no_show_rate: "NO-SHOW RATE",
    saturated_service: "SERVICE CAPACITY",
    peak_demand_hour: "PEAK DEMAND",
    uneven_service_window_load: "WINDOW LOAD",
  };

  return categories[code] ?? "OPERATIONS";
}

function RecommendationIcon() {
  return (
    <svg
      viewBox="0 0 24 24"
      className="h-6 w-6"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.8"
      aria-hidden="true"
    >
      <path d="M9 18h6" />
      <path d="M10 22h4" />
      <path d="M8.5 14.5A7 7 0 1 1 15.5 14.5C14.5 15.3 14 16 14 17h-4c0-1-.5-1.7-1.5-2.5Z" />
      <path d="M12 2V0.5M4.9 4.9 3.8 3.8M19.1 4.9l1.1-1.1" />
    </svg>
  );
}

export default function AiRecommendationsIndex({
  date,
  operational_recommendations: operationalRecommendations,
}: AiRecommendationsIndexProps) {
  const detailedRecommendations =
    operationalRecommendations.recommendations.filter(isDetailedRecommendation);

  const primaryRecommendation = detailedRecommendations[0];
  const recommendationHistory = detailedRecommendations.slice(1);
  const holidayAlert = operationalRecommendations.next_holiday_alert;
  const hasInsufficientData = operationalRecommendations.status === "insufficient_data";

  const primaryTitle = primaryRecommendation
    ? primaryRecommendation.title
    : hasInsufficientData
      ? "Insufficient historical data"
      : "Operations are performing normally";

  const primaryDescription = primaryRecommendation
    ? primaryRecommendation.description
    : hasInsufficientData
      ? "QueueCare AI needs more historical activity before generating a reliable operational recommendation."
      : "No operational alerts were detected for the current analysis period.";

  const primaryAction = primaryRecommendation
    ? primaryRecommendation.suggested_action
    : hasInsufficientData
      ? "Continue collecting operational data."
      : "Continue monitoring the current operation.";

  return (
    <AppLayout>
      <section className="mx-auto max-w-[1180px] space-y-8 pb-12">
        <header>
          <h1 className="text-2xl font-bold tracking-tight text-slate-950">AI Recommendations</h1>

          <p className="mt-1 text-sm text-slate-500">
            Intelligent operational insights based on QueueCare AI data.
          </p>
        </header>

        <article className="overflow-hidden rounded-2xl bg-gradient-to-br from-blue-600 via-blue-600 to-indigo-700 text-white shadow-lg shadow-blue-200/60">
          <div className="grid gap-8 px-7 py-8 md:grid-cols-[1fr_auto] md:px-10 md:py-10">
            <div className="max-w-3xl">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-white/15">
                  <RecommendationIcon />
                </span>

                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.18em] text-blue-100">
                    Main recommendation
                  </p>

                  <p className="mt-1 text-xs text-blue-100">
                    Analysis updated on {formatDate(date)}
                  </p>
                </div>
              </div>

              <h2 className="mt-7 text-2xl font-bold leading-tight md:text-3xl">{primaryTitle}</h2>

              <p className="mt-4 max-w-2xl text-sm leading-7 text-blue-50">{primaryDescription}</p>

              <div className="mt-6 rounded-xl border border-white/15 bg-white/10 px-4 py-3 backdrop-blur-sm">
                <p className="text-xs font-semibold uppercase tracking-wide text-blue-100">
                  Suggested action
                </p>

                <p className="mt-1 text-sm font-medium text-white">{primaryAction}</p>
              </div>
            </div>

            <div className="flex items-start justify-end">
              <span className="rounded-full border border-white/20 bg-white/15 px-4 py-2 text-xs font-semibold backdrop-blur-sm">
                AI insight
              </span>
            </div>
          </div>
        </article>

        <section>
          <div className="mb-4 flex flex-wrap items-end justify-between gap-3">
            <div>
              <h2 className="text-lg font-bold text-slate-950">Recommendation history</h2>

              <p className="mt-1 text-xs text-slate-500">
                Additional operational findings identified by QueueCare AI.
              </p>
            </div>

            <span className="rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-medium text-slate-500">
              {recommendationHistory.length + (holidayAlert ? 1 : 0)} insights
            </span>
          </div>

          {recommendationHistory.length === 0 && !holidayAlert ? (
            <div className="rounded-2xl border border-slate-200 bg-white px-6 py-10 text-center shadow-sm">
              <div className="mx-auto flex h-11 w-11 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                <RecommendationIcon />
              </div>

              <h3 className="mt-4 text-sm font-semibold text-slate-900">
                No additional recommendations
              </h3>

              <p className="mx-auto mt-2 max-w-md text-xs leading-5 text-slate-500">
                New operational findings will appear here when QueueCare AI detects conditions
                requiring attention.
              </p>
            </div>
          ) : (
            <div className="grid gap-4 md:grid-cols-2">
              {recommendationHistory.map((recommendation) => (
                <article
                  key={recommendation.code}
                  className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md"
                >
                  <div className="flex items-start justify-between gap-4">
                    <span className="rounded-full bg-blue-50 px-3 py-1 text-[10px] font-bold tracking-wide text-blue-700">
                      {recommendationCategory(recommendation.code)}
                    </span>

                    <span className="text-[11px] text-slate-400">{formatDate(date)}</span>
                  </div>

                  <h3 className="mt-5 text-base font-bold text-slate-950">
                    {recommendation.title}
                  </h3>

                  <p className="mt-2 text-xs leading-6 text-slate-500">
                    {recommendation.description}
                  </p>

                  <div className="mt-5 border-t border-slate-100 pt-4">
                    <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                      Suggested action
                    </p>

                    <p className="mt-1 text-xs font-medium leading-5 text-slate-700">
                      {recommendation.suggested_action}
                    </p>
                  </div>
                </article>
              ))}

              {holidayAlert && (
                <article className="rounded-2xl border border-amber-200 bg-amber-50/70 p-6 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md">
                  <div className="flex items-start justify-between gap-4">
                    <span className="rounded-full bg-amber-100 px-3 py-1 text-[10px] font-bold tracking-wide text-amber-800">
                      HOLIDAY ALERT
                    </span>

                    <span className="text-[11px] text-amber-700/70">
                      {formatDate(holidayAlert.date)}
                    </span>
                  </div>

                  <h3 className="mt-5 text-base font-bold text-slate-950">
                    {holidayAlert.names.join(" / ")}
                  </h3>

                  <p className="mt-2 text-xs leading-6 text-slate-600">
                    The next public holiday is in {holidayAlert.days_away} days. Review the expected
                    operational demand and staffing requirements.
                  </p>

                  <div className="mt-5 border-t border-amber-200 pt-4">
                    <p className="text-[10px] font-semibold uppercase tracking-wide text-amber-700">
                      Suggested action
                    </p>

                    <p className="mt-1 text-xs font-medium leading-5 text-slate-700">
                      Review staffing for {formatDate(holidayAlert.recommended_staffing_date)}.
                    </p>
                  </div>
                </article>
              )}
            </div>
          )}
        </section>
      </section>
    </AppLayout>
  );
}
