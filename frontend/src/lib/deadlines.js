// Local-time day/week helpers and the worker's deadline buckets.
export function startOfDay(d = new Date()) { const x = new Date(d); x.setHours(0, 0, 0, 0); return x; }
export function endOfDay(d = new Date()) { const x = new Date(d); x.setHours(23, 59, 59, 999); return x; }
export function startOfWeek(d = new Date()) {
  const x = startOfDay(d);
  const day = x.getDay();
  x.setDate(x.getDate() + (day === 0 ? -6 : 1 - day));
  return x;
}
export function endOfWeek(d = new Date()) {
  const e = new Date(startOfWeek(d));
  e.setDate(e.getDate() + 6);
  e.setHours(23, 59, 59, 999);
  return e;
}

// When a task is due (ms). Day-of-week-only tasks are due on the next occurrence of that weekday (today counts).
function dueTimeOf(t) {
  if (t.due_at) return new Date(t.due_at).getTime();
  if (t.due_day_of_week == null) return null;
  const d = startOfDay();
  const todayDow = (d.getDay() + 6) % 7;
  d.setDate(d.getDate() + ((t.due_day_of_week - todayDow + 7) % 7));
  const [hh, mm] = (t.due_time || "23:59").split(":").map(Number);
  d.setHours(hh, mm, 59, 999);
  return d.getTime();
}

export function bucketTasks(tasks) {
  const todayStart = startOfDay().getTime();
  const todayEnd = endOfDay().getTime();
  const weekStart = startOfWeek().getTime();
  const weekEnd = endOfWeek().getTime();
  const out = { dueToday: [], dueThisWeek: [], overdue: [], anytime: [], weeklyPotential: 0, openTotal: 0 };
  tasks.forEach((t) => {
    if (t.status === "completed") return;
    out.openTotal += Number(t.price);
    const due = dueTimeOf(t);
    if (due == null) { out.anytime.push(t); return; }
    if (due < todayStart) out.overdue.push(t);
    else if (due <= todayEnd) out.dueToday.push(t);
    else if (due <= weekEnd) out.dueThisWeek.push(t);
    else out.anytime.push(t);
    if (due >= weekStart && due <= weekEnd) out.weeklyPotential += Number(t.price);
  });
  return out;
}

// Hours clocked today: finished shifts that started today plus every running clock.
export function todayHours(entries, actives, now) {
  const start = startOfDay().getTime();
  let total = 0;
  entries.forEach((e) => {
    if (e.clock_out && new Date(e.clock_in).getTime() >= start) total += e.duration_seconds || 0;
  });
  actives.forEach((a) => {
    const inT = new Date(a.clock_in).getTime();
    if (inT >= start) total += Math.floor((now - inT) / 1000);
  });
  return total / 3600;
}
