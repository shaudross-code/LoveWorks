import { AlarmClock } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DayPicker } from "@/components/AlarmsPanel";
import { deviceTz, repeatSummary, fmtTimeOfDay, fmtAlarmTime, toLocalInput } from "@/lib/alarms";

const MINUTE_OPTIONS = [5, 10, 15, 30, 45, 60, 90, 120, 180, 1440];
const minutesLabel = (m) => (m >= 1440 ? "1 day" : m >= 60 ? `${m / 60} hr${m > 60 ? "s" : ""}` : `${m} min`);

export const ALARM_FORM_DEFAULTS = { alarm_mode: "none", alarm_minutes: "30", alarm_when: "", alarm_days: [], alarm_time: "07:30" };

// Task's stored alarm -> form fields
export function alarmToForm(alarm) {
  if (!alarm) return { ...ALARM_FORM_DEFAULTS };
  if (alarm.mode === "before") return { ...ALARM_FORM_DEFAULTS, alarm_mode: "before", alarm_minutes: String(alarm.minutes) };
  if (alarm.repeat_days?.length) return { ...ALARM_FORM_DEFAULTS, alarm_mode: "exact", alarm_days: alarm.repeat_days, alarm_time: alarm.time_of_day };
  return { ...ALARM_FORM_DEFAULTS, alarm_mode: "exact", alarm_when: alarm.fire_at ? toLocalInput(new Date(alarm.fire_at)) : "" };
}

// Form fields -> API payload (null removes the alarm)
export function formToAlarm(f) {
  if (f.alarm_mode === "before") return { mode: "before", minutes: parseInt(f.alarm_minutes, 10) };
  if (f.alarm_mode === "exact") {
    if (f.alarm_days.length) return { mode: "exact", repeat_days: f.alarm_days, time_of_day: f.alarm_time, tz: deviceTz() };
    return { mode: "exact", fire_at: f.alarm_when ? new Date(f.alarm_when).toISOString() : null };
  }
  return null;
}

export function alarmLabel(alarm) {
  if (!alarm) return "";
  if (alarm.mode === "before") return `${minutesLabel(alarm.minutes)} before due`;
  if (alarm.repeat_days?.length) return `${repeatSummary(alarm.repeat_days)} ${fmtTimeOfDay(alarm.time_of_day)}`;
  return alarm.fire_at ? fmtAlarmTime(alarm.fire_at) : "";
}

const MODES = [
  { value: "none", label: "No alarm" },
  { value: "before", label: "Before it's due" },
  { value: "exact", label: "At a time I pick" },
];

export default function TaskAlarmFields({ form, setForm, workerName }) {
  const set = (patch) => setForm({ ...form, ...patch });
  return (
    <div data-testid="task-alarm-fields" className="rounded-xl border border-yellow-400/15 bg-zinc-900/40 p-3 space-y-3">
      <div className="flex items-center justify-between gap-3">
        <label className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
          <AlarmClock className="w-3.5 h-3.5 text-yellow-400" /> Alarm for {workerName || "the worker"}
        </label>
        <Select value={form.alarm_mode} onValueChange={(v) => set({ alarm_mode: v })}>
          <SelectTrigger data-testid="task-alarm-mode" className="w-44 bg-zinc-900 border-zinc-800 text-white rounded-xl h-9">
            <SelectValue />
          </SelectTrigger>
          <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
            {MODES.map((m) => <SelectItem key={m.value} value={m.value} data-testid={`alarm-mode-${m.value}`}>{m.label}</SelectItem>)}
          </SelectContent>
        </Select>
      </div>

      {form.alarm_mode === "before" && (
        <div className="space-y-1.5">
          <Select value={form.alarm_minutes} onValueChange={(v) => set({ alarm_minutes: v })}>
            <SelectTrigger data-testid="task-alarm-minutes" className="bg-zinc-900 border-zinc-800 text-white rounded-xl h-11">
              <SelectValue />
            </SelectTrigger>
            <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
              {MINUTE_OPTIONS.map((m) => <SelectItem key={m} value={String(m)} data-testid={`alarm-minutes-${m}`}>{minutesLabel(m)} before</SelectItem>)}
            </SelectContent>
          </Select>
          <div className="text-[10px] text-zinc-500">
            Uses the Due time above{form.frequency !== "once" ? " and rings on every due day." : " and the deadline date or day."}
            {!form.due_time && <span className="text-yellow-300"> Set a Due time first.</span>}
          </div>
        </div>
      )}

      {form.alarm_mode === "exact" && (
        <div className="space-y-3">
          <DayPicker days={form.alarm_days} onChange={(d) => set({ alarm_days: d })} />
          {form.alarm_days.length
            ? <Input data-testid="task-alarm-time" type="time" value={form.alarm_time} onChange={(e) => set({ alarm_time: e.target.value })}
                className="bg-zinc-900 border-zinc-800 text-white rounded-xl h-11 [color-scheme:dark]" />
            : <Input data-testid="task-alarm-when" type="datetime-local" value={form.alarm_when} onChange={(e) => set({ alarm_when: e.target.value })}
                className="bg-zinc-900 border-zinc-800 text-white rounded-xl h-11 [color-scheme:dark]" />}
        </div>
      )}
      {form.alarm_mode !== "none" && (
        <div className="text-[10px] text-zinc-500">Rings on their phone and web app, even with iLoveWorks closed. Removed when the task is done.</div>
      )}
    </div>
  );
}
