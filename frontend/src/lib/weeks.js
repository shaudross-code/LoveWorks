// Week ids are the Monday's date (YYYY-MM-DD) in the business timezone, as returned by the server.
const asDate = (d) => new Date(`${d}T12:00:00Z`);

export function shiftWeek(weekStart, n) {
  const d = asDate(weekStart);
  d.setUTCDate(d.getUTCDate() + 7 * n);
  return d.toISOString().slice(0, 10);
}

export function fmtDay(d, opts = { month: "short", day: "numeric" }) {
  return asDate(d).toLocaleDateString(undefined, { ...opts, timeZone: "UTC" });
}

export const weekday = (d) => fmtDay(d, { weekday: "short" });

export function weekRange(start, last) {
  return `${fmtDay(start)} – ${fmtDay(last, { month: asDate(start).getUTCMonth() === asDate(last).getUTCMonth() ? undefined : "short", day: "numeric" })}`;
}

export const money = (v) => `$${Number(v || 0).toFixed(2)}`;
