import type {
  DetailedOperationalRecommendation,
  NextHolidayAlert,
  OperationalRecommendation,
  OperationalRecommendations,
} from "../types";

type OperationalRecommendationCardsProps = {
  operationalRecommendations: OperationalRecommendations;
};

function isDetailedRecommendation(
  recommendation: OperationalRecommendation,
): recommendation is DetailedOperationalRecommendation {
  return "title" in recommendation;
}

function formatHolidayDate(value: string) {
  const [year, month, day] = value.split("-").map(Number);

  return new Intl.DateTimeFormat("en-US", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(year, month - 1, day));
}

function daysUntilHoliday(daysAway: number) {
  if (daysAway === 1) {
    return "The next public holiday is tomorrow.";
  }

  return `The next public holiday is in ${daysAway} days.`;
}

function historicalDemandMessage(alert: NextHolidayAlert) {
  const demandChange = alert.demand_change_percentage;

  if (!alert.historical_data_available || demandChange === null) {
    return "There is not enough post-holiday history yet to estimate a reliable demand change.";
  }

  if (demandChange === 0) {
    return "Historical data indicates that demand on the next business day usually remains stable.";
  }

  const direction = demandChange > 0 ? "increase" : "decrease";

  return `Historical data indicates that demand on the next business day may ${direction} by ${Math.abs(
    demandChange,
  )}%.`;
}

export default function OperationalRecommendationCards({
  operationalRecommendations,
}: OperationalRecommendationCardsProps) {
  const primaryRecommendation =
    operationalRecommendations.recommendations.find(isDetailedRecommendation);

  const nextHolidayAlert = operationalRecommendations.next_holiday_alert;

  const hasInsufficientData = operationalRecommendations.status === "insufficient_data";

  return (
    <div className={`grid gap-3 ${nextHolidayAlert ? "lg:grid-cols-2" : ""}`}>
      <article className="rounded-xl border border-blue-100 bg-blue-50 px-4 py-3">
        <p className="text-[10px] font-semibold uppercase tracking-wide text-blue-600">
          Primary recommendation
        </p>

        <p className="mt-1 text-xs font-semibold text-slate-900">
          {primaryRecommendation
            ? primaryRecommendation.title
            : hasInsufficientData
              ? "Insufficient historical data"
              : "No operational alerts detected"}
        </p>

        <p className="mt-1 text-[10px] leading-relaxed text-slate-600">
          {primaryRecommendation
            ? primaryRecommendation.description
            : hasInsufficientData
              ? "More historical activity is required before generating an operational recommendation."
              : "Current historical indicators remain within the configured thresholds."}
        </p>

        {primaryRecommendation && (
          <p className="mt-2 text-[10px] font-medium text-blue-700">
            Suggested action: {primaryRecommendation.suggested_action}
          </p>
        )}
      </article>

      {nextHolidayAlert && (
        <article className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-amber-700">
            Holiday alert
          </p>

          <p className="mt-1 text-xs font-semibold text-slate-900">
            {nextHolidayAlert.names.join(" / ")}
          </p>

          <p className="mt-1 text-[10px] leading-relaxed text-slate-600">
            {formatHolidayDate(nextHolidayAlert.date)}.{" "}
            {daysUntilHoliday(nextHolidayAlert.days_away)}
          </p>

          <p className="mt-2 text-[10px] leading-relaxed text-slate-600">
            {historicalDemandMessage(nextHolidayAlert)}
          </p>

          <p className="mt-2 text-[10px] font-medium text-amber-800">
            Review staffing for {formatHolidayDate(nextHolidayAlert.recommended_staffing_date)}.
          </p>
        </article>
      )}
    </div>
  );
}
