import type {
  DetailedOperationalRecommendation,
  OperationalRecommendation,
  OperationalRecommendations,
  PriorityOperationalRecommendation,
} from "../types";

type OperationalRecommendationCardsProps = {
  operationalRecommendations: OperationalRecommendations;
};

function isDetailedRecommendation(
  recommendation: OperationalRecommendation,
): recommendation is DetailedOperationalRecommendation {
  return "title" in recommendation;
}

function isHolidayRecommendation(
  recommendation: OperationalRecommendation,
): recommendation is PriorityOperationalRecommendation {
  return (
    "priority" in recommendation &&
    (recommendation.code === "holiday_operational_review" ||
      recommendation.code === "adjacent_holiday_operational_review")
  );
}

function holidayMessage(recommendation: PriorityOperationalRecommendation) {
  if (recommendation.code === "holiday_operational_review") {
    return {
      title: "Holiday operational review",
      description:
        "Today is a public holiday. Review staffing and expected demand before beginning operations.",
    };
  }

  return {
    title: "Adjacent holiday operational review",
    description:
      "The selected date is adjacent to a public holiday. Demand may differ from the usual historical pattern.",
  };
}

export default function OperationalRecommendationCards({
  operationalRecommendations,
}: OperationalRecommendationCardsProps) {
  const primaryRecommendation =
    operationalRecommendations.recommendations.find(isDetailedRecommendation);

  const holidayRecommendation =
    operationalRecommendations.recommendations.find(isHolidayRecommendation);

  const holidayContent = holidayRecommendation ? holidayMessage(holidayRecommendation) : null;

  const hasInsufficientData = operationalRecommendations.status === "insufficient_data";

  return (
    <div className={`grid gap-3 ${holidayContent ? "lg:grid-cols-2" : ""}`}>
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

      {holidayContent && (
        <article className="rounded-xl border border-amber-100 bg-amber-50 px-4 py-3">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-amber-700">
            Holiday alert
          </p>

          <p className="mt-1 text-xs font-semibold text-slate-900">{holidayContent.title}</p>

          <p className="mt-1 text-[10px] leading-relaxed text-slate-600">
            {holidayContent.description}
          </p>
        </article>
      )}
    </div>
  );
}
