import AppLayout from "../../layouts/AppLayout";
import type {
  DetailedOperationalRecommendation,
  OperationalRecommendation,
  OperationalRecommendations,
} from "../dashboard/types";
import AiAssistantChat from "./components/AiAssistantChat";

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
      className="h-5 w-5"
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

  const totalInsights = recommendationHistory.length + (holidayAlert ? 1 : 0);

  return (
    <AppLayout>
      <section className="mx-auto max-w-[1500px] space-y-5">
        <header className="flex flex-col gap-3 rounded-2xl border border-slate-200 bg-white px-5 py-4 shadow-sm sm:flex-row sm:items-center sm:justify-between">
          <div>
            <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold uppercase tracking-[0.14em] text-blue-700">
              AI insights
            </span>

            <h1 className="mt-2 text-2xl font-bold tracking-tight text-slate-950">
              AI Recommendations
            </h1>

            <p className="mt-1 text-sm text-slate-500">
              Intelligent operational insights based on QueueCare AI data.
            </p>
          </div>

          <div className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-right">
            <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-slate-400">
              Analysis date
            </p>

            <p className="mt-1 text-xs font-bold text-slate-700">{formatDate(date)}</p>
          </div>
        </header>

        <div className="space-y-5">
          <div className="min-w-0 space-y-5">
            <article className="overflow-hidden rounded-2xl bg-gradient-to-br from-blue-600 via-blue-700 to-indigo-800 text-white shadow-lg shadow-blue-200/50">
              <div className="p-6">
                <div className="flex flex-wrap items-start justify-between gap-4">
                  <div className="flex items-center gap-3">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-white/15 ring-1 ring-inset ring-white/10">
                      <RecommendationIcon />
                    </span>

                    <div>
                      <p className="text-[10px] font-bold uppercase tracking-[0.16em] text-blue-100">
                        Main recommendation
                      </p>

                      <p className="mt-1 text-[11px] text-blue-100/80">
                        Highest priority operational insight
                      </p>
                    </div>
                  </div>

                  <span className="rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-[10px] font-bold uppercase tracking-wide text-blue-50 backdrop-blur-sm">
                    AI insight
                  </span>
                </div>

                <h2 className="mt-6 max-w-3xl text-2xl font-bold leading-tight">{primaryTitle}</h2>

                <p className="mt-3 max-w-3xl text-sm leading-6 text-blue-50/90">
                  {primaryDescription}
                </p>

                <div className="mt-5 rounded-xl border border-white/15 bg-white/10 px-4 py-3 backdrop-blur-sm">
                  <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-blue-100">
                    Suggested action
                  </p>

                  <p className="mt-1.5 text-sm font-semibold leading-6 text-white">
                    {primaryAction}
                  </p>
                </div>
              </div>
            </article>

            <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
              <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 px-5 py-4">
                <div>
                  <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-slate-400">
                    Historical insights
                  </p>

                  <h2 className="mt-1 text-lg font-bold text-slate-950">Recommendation history</h2>
                </div>

                <span className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-bold text-slate-600">
                  {totalInsights} {totalInsights === 1 ? "insight" : "insights"}
                </span>
              </div>

              <div className="p-4">
                {recommendationHistory.length === 0 && !holidayAlert ? (
                  <div className="rounded-xl border border-dashed border-slate-300 px-5 py-9 text-center">
                    <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600">
                      <RecommendationIcon />
                    </div>

                    <h3 className="mt-3 text-sm font-bold text-slate-800">
                      No additional recommendations
                    </h3>

                    <p className="mx-auto mt-1 max-w-md text-xs leading-5 text-slate-500">
                      New operational findings will appear here when QueueCare AI detects conditions
                      requiring attention.
                    </p>
                  </div>
                ) : (
                  <div className="grid gap-3 md:grid-cols-2">
                    {recommendationHistory.map((recommendation) => (
                      <article
                        key={recommendation.code}
                        className="rounded-xl border border-slate-200 bg-white p-4 transition hover:border-blue-200 hover:shadow-sm"
                      >
                        <div className="flex items-start justify-between gap-3">
                          <span className="rounded-full bg-blue-50 px-2.5 py-1 text-[10px] font-bold tracking-wide text-blue-700">
                            {recommendationCategory(recommendation.code)}
                          </span>

                          <span className="text-[10px] text-slate-400">{formatDate(date)}</span>
                        </div>

                        <h3 className="mt-4 text-sm font-bold leading-5 text-slate-950">
                          {recommendation.title}
                        </h3>

                        <p className="mt-2 text-xs leading-5 text-slate-500">
                          {recommendation.description}
                        </p>

                        <div className="mt-4 rounded-xl bg-slate-50 px-3 py-3">
                          <p className="text-[9px] font-bold uppercase tracking-[0.12em] text-slate-400">
                            Suggested action
                          </p>

                          <p className="mt-1 text-xs font-semibold leading-5 text-slate-700">
                            {recommendation.suggested_action}
                          </p>
                        </div>
                      </article>
                    ))}

                    {holidayAlert && (
                      <article className="rounded-xl border border-amber-200 bg-amber-50/70 p-4 transition hover:shadow-sm">
                        <div className="flex items-start justify-between gap-3">
                          <span className="rounded-full bg-amber-100 px-2.5 py-1 text-[10px] font-bold tracking-wide text-amber-800">
                            HOLIDAY ALERT
                          </span>

                          <span className="text-[10px] text-amber-700/70">
                            {formatDate(holidayAlert.date)}
                          </span>
                        </div>

                        <h3 className="mt-4 text-sm font-bold leading-5 text-slate-950">
                          {holidayAlert.names.join(" / ")}
                        </h3>

                        <p className="mt-2 text-xs leading-5 text-slate-600">
                          The next public holiday is in {holidayAlert.days_away} days. Review
                          expected operational demand and staffing requirements.
                        </p>

                        <div className="mt-4 rounded-xl border border-amber-200/70 bg-white/60 px-3 py-3">
                          <p className="text-[9px] font-bold uppercase tracking-[0.12em] text-amber-700">
                            Suggested action
                          </p>

                          <p className="mt-1 text-xs font-semibold leading-5 text-slate-700">
                            Review staffing for {formatDate(holidayAlert.recommended_staffing_date)}
                            .
                          </p>
                        </div>
                      </article>
                    )}
                  </div>
                )}
              </div>
            </section>
          </div>

          <AiAssistantChat />
        </div>
      </section>
    </AppLayout>
  );
}
