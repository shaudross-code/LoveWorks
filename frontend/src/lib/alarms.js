import api from "@/lib/api";

export const ALARMS_CHANGED = "alarms-changed";
export const OPEN_ALARM_DIALOG = "open-alarm-dialog";

export const listAlarms = () => api.get("/alarms").then((r) => r.data);
export const createAlarm = (body) => api.post("/alarms", { source: "web", ...body }).then((r) => r.data);
export const cancelAlarm = (id) => api.delete(`/alarms/${id}`);
export const snoozeAlarm = (id, minutes = 10) => api.post(`/alarms/${id}/snooze`, { minutes }).then((r) => r.data);
export const dismissAlarm = (id) => api.post(`/alarms/${id}/dismiss`);

export const announceAlarmsChanged = () => window.dispatchEvent(new Event(ALARMS_CHANGED));
export const openAlarmDialog = (prefill = {}) => window.dispatchEvent(new CustomEvent(OPEN_ALARM_DIALOG, { detail: prefill }));

const pad = (n) => String(n).padStart(2, "0");

// Value for <input type="datetime-local"> in the device's own timezone.
export function toLocalInput(d) {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

// Default: 30 min before the task's due time (today, or tomorrow if passed); else one hour from now.
export function defaultFireDate(dueTime) {
  const now = new Date();
  if (dueTime) {
    const [h, m] = dueTime.split(":").map(Number);
    const d = new Date(now);
    d.setHours(h, m - 30, 0, 0);
    if (d <= now) d.setDate(d.getDate() + 1);
    return d;
  }
  const d = new Date(now.getTime() + 60 * 60 * 1000);
  d.setSeconds(0, 0);
  return d;
}

export function fmtAlarmTime(iso) {
  return new Date(iso).toLocaleString(undefined, { weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit" });
}
