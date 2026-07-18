export function formatDate(date: string) {
  const parsedDate = new Date(`${date}T00:00:00`);

  return new Intl.DateTimeFormat("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  }).format(parsedDate);
}

export function formatMinutes(value: number | null) {
  return value === null ? "No data" : `${value.toFixed(2)} min`;
}
