import { ALARM_FORM_DEFAULTS, alarmToForm, formToAlarm } from "@/components/TaskAlarmFields";

export const TASK_STATUS_TABS = ["all", "assigned", "in_progress", "completed"];
export const STATUS_STYLE = {
  assigned: "bg-zinc-800 text-zinc-300",
  in_progress: "bg-yellow-400/15 text-yellow-300",
  completed: "bg-green-400/15 text-green-400",
};
export const FREQUENCIES = [
  { value: "once", label: "One-time" },
  { value: "daily", label: "Daily" },
  { value: "weekly", label: "Weekly" },
  { value: "monthly", label: "Monthly" },
];
export const PAYOUTS = [
  { value: "per_task", label: "On completion" },
  { value: "daily", label: "Daily" },
  { value: "weekly", label: "Weekly" },
  { value: "monthly", label: "Monthly" },
];
export const DAYS_OF_WEEK = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
  .map((label, i) => ({ value: String(i), label }));
export const FREQ_LABEL = Object.fromEntries(FREQUENCIES.map((f) => [f.value, f.label]));
export const PAYOUT_LABEL = Object.fromEntries(PAYOUTS.map((p) => [p.value, p.label]));
export const DOW_LABEL = Object.fromEntries(DAYS_OF_WEEK.map((d) => [d.value, d.label]));

export const EMPTY_TASK = {
  title: "", description: "", price: "", assignee_id: "",
  due_at: "", due_time: "", due_day_of_week: "",
  estimated_hours: "", daily_hours: "", daily_hours_unit: "hours",
  frequency: "once", payout_schedule: "per_task",
  ...ALARM_FORM_DEFAULTS,
};

function toDateInput(iso) {
  if (!iso) return "";
  try { return new Date(iso).toISOString().slice(0, 10); } catch { return ""; }
}

export function taskToForm(t) {
  const dh = t.daily_hours;
  const useMinutes = dh != null && dh > 0 && dh < 1;
  return {
    title: t.title || "",
    description: t.description || "",
    price: String(t.price ?? ""),
    assignee_id: t.assignee_id,
    due_at: toDateInput(t.due_at),
    estimated_hours: t.estimated_hours != null ? String(t.estimated_hours) : "",
    daily_hours: dh != null ? String(useMinutes ? Math.round(dh * 60 * 100) / 100 : dh) : "",
    daily_hours_unit: useMinutes ? "minutes" : "hours",
    due_time: t.due_time || "",
    due_day_of_week: t.due_day_of_week != null ? String(t.due_day_of_week) : "",
    frequency: t.frequency || "once",
    payout_schedule: t.payout_schedule || "per_task",
    ...alarmToForm(t.alarm),
  };
}

export function validateTask(form) {
  if (!form.assignee_id) return "Pick a worker";
  if (!form.title.trim()) return "Title is required";
  const price = parseFloat(form.price);
  if (!Number.isFinite(price) || price < 0) return "Enter a price (0 or more)";
  return null;
}

function dailyHoursOf(form) {
  if (!form.daily_hours) return null;
  const v = parseFloat(form.daily_hours);
  if (!Number.isFinite(v) || v < 0) return null;
  return form.daily_hours_unit === "minutes" ? v / 60 : v;
}

export function taskPayload(form) {
  return {
    title: form.title.trim(),
    description: form.description,
    price: parseFloat(form.price),
    assignee_id: form.assignee_id,
    due_at: form.due_at || null,
    due_time: form.due_time || null,
    due_day_of_week: form.due_day_of_week === "" ? -1 : parseInt(form.due_day_of_week, 10),
    estimated_hours: form.estimated_hours ? parseFloat(form.estimated_hours) : null,
    daily_hours: dailyHoursOf(form),
    frequency: form.frequency,
    payout_schedule: form.payout_schedule,
    alarm: formToAlarm(form),
  };
}
