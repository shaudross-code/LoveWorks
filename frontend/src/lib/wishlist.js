import { AlertTriangle, CheckCircle2, Clock } from "lucide-react";

export const QUICK_QUOTES = [
  "🛒 Ordering it soon!",
  "✅ It's already ordered.",
  "📦 It will be shipped soon.",
  "👏 Good job — you earned it!",
  "🌟 So proud of you!",
  "🎉 Way to go — crushed it!",
];

export const STATUS_TABS = ["all", "open", "overdue", "completed"];

export const PERIODS = [
  { value: "once", label: "One-time" },
  { value: "daily", label: "Daily" },
  { value: "weekly", label: "Weekly" },
  { value: "monthly", label: "Monthly" },
  { value: "yearly", label: "Yearly" },
];
export const PERIOD_LABEL = Object.fromEntries(PERIODS.map((p) => [p.value, p.label]));

export function statusOf(g) {
  if (g.status === "completed") return "completed";
  if (g.deadline && new Date(g.deadline).getTime() < Date.now()) return "overdue";
  return "open";
}

const BADGES = {
  open: { Icon: Clock, cls: "bg-zinc-800 text-zinc-300", label: "In progress" },
  overdue: { Icon: AlertTriangle, cls: "bg-red-400/15 text-red-400", label: "Overdue" },
  completed: { Icon: CheckCircle2, cls: "bg-green-400/15 text-green-400", label: "Achieved" },
};
export const statusBadge = (s) => BADGES[s] || BADGES.open;

export const isAhead = (g) => Boolean(
  g.status === "completed" && g.deadline && g.completed_at && new Date(g.completed_at) <= new Date(g.deadline),
);

// Tab counts and money totals for a list of goals/trips.
export function summarize(goals) {
  const counts = { all: goals.length, open: 0, overdue: 0, completed: 0 };
  const totals = { all: 0, completed: 0, outstanding: 0 };
  goals.forEach((g) => {
    const s = statusOf(g);
    const v = Number(g.target_amount || 0);
    counts[s] += 1;
    totals.all += v;
    if (s === "completed") totals.completed += v; else totals.outstanding += v;
  });
  return { counts, totals };
}

export const EMPTY_GOAL_FORM = { title: "", product_link: "", deadline: "", target_amount: "", period: "weekly", allocation_percent: "100" };

export const emptyAssignForm = (assigneeId = "") => ({ ...EMPTY_GOAL_FORM, assignee_id: assigneeId });

export function goalToForm(g) {
  return {
    title: g.title || "",
    product_link: g.product_link || "",
    deadline: g.deadline ? String(g.deadline).slice(0, 10) : "",
    target_amount: g.target_amount != null ? String(g.target_amount) : "",
    period: g.period || "weekly",
    allocation_percent: g.allocation_percent != null ? String(g.allocation_percent) : "100",
  };
}

// Query string for POST /goals (the endpoint takes query params + an optional photo).
export function goalCreateParams(form, kind, assigneeId) {
  const p = new URLSearchParams();
  p.set("title", form.title.trim());
  if (assigneeId) p.set("assignee_id", assigneeId);
  p.set("kind", kind);
  if (form.target_amount) p.set("target_amount", form.target_amount);
  if (form.period) p.set("period", form.period);
  if (form.allocation_percent !== "") p.set("allocation_percent", form.allocation_percent);
  if (form.deadline) p.set("deadline", form.deadline);
  if (form.product_link.trim()) p.set("product_link", form.product_link.trim());
  return p.toString();
}

export function goalEditPayload(form) {
  return {
    title: form.title.trim() || undefined,
    product_link: form.product_link.trim(),
    deadline: form.deadline || null,
    target_amount: form.target_amount ? parseFloat(form.target_amount) : null,
    period: form.period,
    allocation_percent: form.allocation_percent ? parseFloat(form.allocation_percent) : 0,
  };
}

export const celebrateText = (g) => (g.deadline && new Date(g.deadline).getTime() > Date.now()
  ? `Wow, ahead of schedule — proud of you for hitting "${g.title}"!`
  : `Goal achieved — nice work on "${g.title}"!`);
