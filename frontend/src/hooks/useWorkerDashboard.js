import { useCallback, useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import api, { attempt } from "@/lib/api";
import { activityOf } from "@/lib/activities";
import { bucketTasks } from "@/lib/deadlines";

// Worker dashboard data (running clocks, tasks, shifts, week) and its actions.
export function useWorkerDashboard() {
  const [actives, setActives] = useState([]);
  const [tasks, setTasks] = useState([]);
  const [entries, setEntries] = useState([]);
  const [weekly, setWeekly] = useState({ streak_days: 0, completions_by_day: [] });
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    const [a, t, e, wk] = await Promise.all([
      api.get("/time/active"), api.get("/tasks"), api.get("/time/entries"), api.get("/me/weekly-activity"),
    ]);
    setActives(Array.isArray(a.data) ? a.data : (a.data?.id ? [a.data] : []));
    setTasks(t.data);
    setEntries(e.data);
    setWeekly(wk.data);
  }, []);
  useEffect(() => { load(); }, [load]);

  const withBusy = async (call, message) => {
    setBusy(true);
    const ok = await attempt(call, message);
    setBusy(false);
    if (ok) load();
    return Boolean(ok);
  };

  const clockIn = (key) => withBusy(() => api.post("/time/clock-in", { activity: key }),
    key === "clocked_in" ? "Clocked in" : `Clocked in — ${activityOf(key).label}`);
  const clockOut = (entryId = null) => withBusy(
    () => api.post(entryId ? `/time/clock-out?entry_id=${encodeURIComponent(entryId)}` : "/time/clock-out"),
    entryId ? "Clock stopped" : "Clocked out",
  );
  const setStatus = async (t, status) => {
    if (!(await attempt(() => api.patch(`/tasks/${t.id}`, { status })))) return;
    load();
    if (status === "completed") toast.success(`+$${Number(t.price).toFixed(2)} earned`);
  };

  const deadlines = useMemo(() => bucketTasks(tasks), [tasks]);
  const groups = useMemo(() => ({
    open: tasks.filter((t) => t.status !== "completed"),
    done: tasks.filter((t) => t.status === "completed"),
  }), [tasks]);

  return { actives, tasks, entries, weekly, busy, deadlines, groups, clockIn, clockOut, setStatus };
}
