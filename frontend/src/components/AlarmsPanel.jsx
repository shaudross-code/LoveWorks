import { useCallback, useEffect, useState } from "react";
import { AlarmClock, Plus, Trash2, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { formatApiError } from "@/lib/api";
import PushStatus from "@/components/PushStatus";
import {
  listAlarms, createAlarm, cancelAlarm, announceAlarmsChanged, defaultFireDate, toLocalInput, fmtAlarmTime,
  ALARMS_CHANGED, OPEN_ALARM_DIALOG, DAY_LABELS, WEEKDAYS, deviceTz, repeatSummary, fmtTimeOfDay,
} from "@/lib/alarms";

function DayPicker({ days, onChange }) {
  const toggle = (d) => onChange(days.includes(d) ? days.filter((x) => x !== d) : [...days, d].sort());
  const isWeekdays = days.length === 5 && WEEKDAYS.every((d) => days.includes(d));
  return (
    <div data-testid="alarm-repeat-picker">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs uppercase tracking-widest text-zinc-500">Repeat</span>
        <button type="button" data-testid="alarm-weekdays-btn" onClick={() => onChange(isWeekdays ? [] : WEEKDAYS)}
          className={`text-xs rounded-full px-3 h-7 border transition-colors ${isWeekdays ? "bg-yellow-400 text-black border-yellow-400" : "border-yellow-400/30 text-yellow-300 hover:bg-yellow-400/10"}`}>
          Weekdays
        </button>
      </div>
      <div className="flex gap-1.5">
        {DAY_LABELS.map((label, d) => (
          <button type="button" key={label} data-testid={`alarm-day-${d}`} aria-pressed={days.includes(d)} onClick={() => toggle(d)}
            className={`flex-1 h-9 rounded-full text-xs font-semibold transition-colors ${days.includes(d) ? "bg-yellow-400 text-black" : "bg-white/5 text-zinc-400 hover:bg-white/10"}`}>
            {label[0]}
          </button>
        ))}
      </div>
    </div>
  );
}

function AlarmDialog({ open, prefill, onClose }) {
  const [title, setTitle] = useState("");
  const [when, setWhen] = useState("");
  const [note, setNote] = useState("");
  const [days, setDays] = useState([]);
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    if (!open) return;
    setTitle(prefill.title || "");
    setNote("");
    setDays([]);
    setWhen(toLocalInput(defaultFireDate(prefill.due_time)));
  }, [open, prefill]);

  const repeating = days.length > 0;
  const timeOfDay = when.slice(11, 16);

  const save = async () => {
    if (!title.trim() || !when) return toast.error("Add a name and a time.");
    setBusy(true);
    try {
      const base = { title: title.trim(), note: note.trim() || null, task_id: prefill.task_id || null };
      const body = repeating
        ? { ...base, repeat_days: days, time_of_day: timeOfDay, tz: deviceTz() }
        : { ...base, fire_at: new Date(when).toISOString() };
      const a = await createAlarm(body);
      toast.success(repeating ? `Alarm set: ${repeatSummary(days)} at ${fmtTimeOfDay(timeOfDay)}` : `Alarm set for ${fmtAlarmTime(a.fire_at)}`);
      announceAlarmsChanged();
      onClose();
    } catch (e) { toast.error(formatApiError(e)); } finally { setBusy(false); }
  };

  return (
    <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent data-testid="alarm-dialog" className="bg-[#121214] border-yellow-400/20 text-white">
        <DialogHeader><DialogTitle className="flex items-center gap-2"><AlarmClock className="w-5 h-5 text-yellow-400" /> Set an alarm</DialogTitle></DialogHeader>
        <div className="space-y-3">
          <Input data-testid="alarm-title-input" placeholder="What's it for?" value={title} maxLength={120} onChange={(e) => setTitle(e.target.value)} />
          <DayPicker days={days} onChange={setDays} />
          {repeating
            ? <Input data-testid="alarm-time-of-day-input" type="time" value={timeOfDay} onChange={(e) => setWhen(`${when.slice(0, 11)}${e.target.value}`)} />
            : <Input data-testid="alarm-time-input" type="datetime-local" value={when} onChange={(e) => setWhen(e.target.value)} />}
          <Input data-testid="alarm-note-input" placeholder="Note (optional)" value={note} maxLength={300} onChange={(e) => setNote(e.target.value)} />
        </div>
        <DialogFooter>
          <Button data-testid="alarm-save-btn" onClick={save} disabled={busy} className="bg-yellow-400 hover:bg-yellow-300 text-black rounded-full">
            {busy && <Loader2 className="w-4 h-4 animate-spin mr-1" />} Save alarm
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function AlarmItem({ a, onCancel }) {
  return (
    <li data-testid={`alarm-item-${a.id}`} className="flex items-center gap-3 py-2.5">
      <AlarmClock className={`w-4 h-4 shrink-0 ${a.status === "scheduled" ? "text-yellow-400" : "text-zinc-600"}`} />
      <div className="flex-1 min-w-0">
        <div className="text-sm font-medium truncate">{a.title}</div>
        <div className="text-xs text-zinc-500">
          {a.repeat_days?.length
            ? <span data-testid={`alarm-repeat-${a.id}`}>{repeatSummary(a.repeat_days)} · {fmtTimeOfDay(a.time_of_day)} · next {fmtAlarmTime(a.fire_at)}</span>
            : <>{fmtAlarmTime(a.fire_at)}{a.status === "fired" ? " · rang" : ""}</>}
        </div>
      </div>
      {a.status === "scheduled" && (
        <button data-testid={`alarm-cancel-${a.id}`} onClick={() => onCancel(a.id)} aria-label="Cancel alarm"
          className="w-8 h-8 rounded-full grid place-items-center text-zinc-500 hover:text-red-300 hover:bg-red-500/10 transition-colors">
          <Trash2 className="w-4 h-4" />
        </button>
      )}
    </li>
  );
}

export default function AlarmsPanel() {
  const [alarms, setAlarms] = useState([]);
  const [dialog, setDialog] = useState({ open: false, prefill: {} });
  const load = useCallback(() => listAlarms().then(setAlarms).catch(() => {}), []);
  useEffect(() => {
    load();
    const onOpen = (e) => setDialog({ open: true, prefill: e.detail || {} });
    window.addEventListener(ALARMS_CHANGED, load);
    window.addEventListener(OPEN_ALARM_DIALOG, onOpen);
    return () => { window.removeEventListener(ALARMS_CHANGED, load); window.removeEventListener(OPEN_ALARM_DIALOG, onOpen); };
  }, [load]);

  const cancel = async (id) => {
    try { await cancelAlarm(id); toast.success("Alarm cancelled"); announceAlarmsChanged(); } catch (e) { toast.error(formatApiError(e)); }
  };

  return (
    <section data-testid="alarms-panel" className="rounded-2xl border border-yellow-400/15 bg-[#121214] p-5 sm:p-6">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="font-display font-semibold text-base md:text-lg flex items-center gap-2"><AlarmClock className="w-5 h-5 text-yellow-400" /> Alarms</h2>
          <p className="text-xs text-zinc-500 mt-0.5">Rings here while the app is open, and as an alert on this device when it&apos;s closed.</p>
        </div>
        <button data-testid="alarm-new-btn" onClick={() => setDialog({ open: true, prefill: {} })}
          className="inline-flex items-center gap-1.5 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full px-3.5 h-9 text-sm transition-colors">
          <Plus className="w-4 h-4" /> New
        </button>
      </div>
      {alarms.length === 0
        ? <div data-testid="alarms-empty" className="mt-4 text-sm text-zinc-500">No alarms yet. Tap the alarm icon on any task, or New.</div>
        : <ul className="mt-3 divide-y divide-white/5">{alarms.map((a) => <AlarmItem key={a.id} a={a} onCancel={cancel} />)}</ul>}
      <div className="mt-4"><PushStatus /></div>
      <AlarmDialog open={dialog.open} prefill={dialog.prefill} onClose={() => setDialog({ open: false, prefill: {} })} />
    </section>
  );
}
