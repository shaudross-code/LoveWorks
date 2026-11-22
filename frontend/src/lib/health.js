import api from "@/lib/api";

export const getMyHealth = () => api.get("/health/me").then((r) => r.data);
export const setHealthSharing = (share) => api.patch("/health/sharing", { share }).then((r) => r.data);

export const kgToLb = (kg) => Math.round(kg * 2.20462 * 10) / 10;
export const fmtKcal = (v) => (v == null ? "—" : Math.round(v).toLocaleString());

export function timeAgo(iso) {
  if (!iso) return "";
  const mins = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return `${mins} min ago`;
  const h = Math.round(mins / 60);
  return h < 24 ? `${h} hr ago` : new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric" });
}

export const sourceLabel = (s) => (s === "watch_live" ? "live from Apple Watch" : "from Apple Health");
export const weightSourceLabel = (s) => (s === "scale_bluetooth" ? "from your scale (Bluetooth)" : "from Apple Health");
