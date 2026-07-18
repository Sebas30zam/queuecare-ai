import type { HourlyActivity } from "../types";

type HourlyLineChartProps = {
  activity: HourlyActivity[];
};

export default function HourlyLineChart({ activity }: HourlyLineChartProps) {
  const visibleActivity = activity;

  if (visibleActivity.length === 0) {
    return (
      <div className="flex h-52 items-center justify-center text-xs text-slate-400">
        No hourly activity today.
      </div>
    );
  }

  const width = 620;
  const height = 205;
  const paddingLeft = 34;
  const paddingRight = 16;
  const paddingTop = 12;
  const paddingBottom = 28;
  const chartWidth = width - paddingLeft - paddingRight;
  const chartHeight = height - paddingTop - paddingBottom;
  const maxValue = Math.max(...visibleActivity.map((item) => item.tickets_created), 1);

  const points = visibleActivity.map((item, index) => {
    const x = paddingLeft + (index / Math.max(visibleActivity.length - 1, 1)) * chartWidth;
    const y = paddingTop + chartHeight - (item.tickets_created / maxValue) * chartHeight;

    return {
      ...item,
      x,
      y,
    };
  });

  return (
    <svg
      viewBox={`0 0 ${width} ${height}`}
      className="h-52 w-full"
      role="img"
      aria-label="Tickets created por hora"
    >
      {[0, 0.25, 0.5, 0.75, 1].map((percentage) => {
        const y = paddingTop + chartHeight * percentage;

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
        );
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
          <circle cx={point.x} cy={point.y} r="4" fill="#ffffff" stroke="#3b82f6" strokeWidth="2" />

          <text x={point.x} y={height - 8} textAnchor="middle" fontSize="9" fill="#64748b">
            {point.label}
          </text>
        </g>
      ))}
    </svg>
  );
}
