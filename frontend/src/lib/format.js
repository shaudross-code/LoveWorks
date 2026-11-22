export function fmtClock(seconds) {
  const s = Math.max(0, Math.floor(seconds));
  const pad = (n) => String(n).padStart(2, "0");
  return `${pad(Math.floor(s / 3600))}:${pad(Math.floor((s % 3600) / 60))}:${pad(s % 60)}`;
}

export function fmtTime12(hhmm) {
  if (!hhmm) return "";
  const [h, m] = hhmm.split(":").map(Number);
  if (!Number.isFinite(h)) return hhmm;
  const h12 = h % 12 === 0 ? 12 : h % 12;
  return `${h12}:${String(m).padStart(2, "0")} ${h >= 12 ? "PM" : "AM"}`;
}

export function fmtDailyHours(h) {
  if (h == null) return "";
  const v = Number(h);
  if (!Number.isFinite(v)) return "";
  return v < 1 ? `${Math.round(v * 60)}m/day` : `${Math.round(v * 100) / 100}h/day`;
}

function fmtDateWith(iso, options) {
  if (!iso) return null;
  try { return new Date(iso).toLocaleDateString(undefined, options); } catch { return null; }
}

export const fmtDateLong = (iso) => fmtDateWith(iso, { month: "short", day: "numeric", year: "numeric" });
export const fmtDateDay = (iso) => fmtDateWith(iso, { weekday: "short", month: "short", day: "numeric" });
export const fmtDateShort = (iso) => fmtDateWith(iso, { month: "short", day: "numeric" });

export function hostOf(url) {
  try { return new URL(url).hostname; } catch { return url; }
}

export const plural = (n, one = "", many = "s") => (n === 1 ? one : many);
