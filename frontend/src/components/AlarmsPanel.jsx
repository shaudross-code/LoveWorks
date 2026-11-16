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
  ALARMS_CHANGED, OPEN_ALARM_DIALOG,
} from "@/lib/alarms";

function AlarmDialog({ open, prefill, onClose }) {
  const [title, setTitle] = useState("");
  const [when, setWhen] = useState("");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    if (!open) return;
    setTitle(prefill.title || "");
    setNote("");
    setWhen(toLocalInput(defaultFireDate(prefill.due_time)));
  }, [open, prefill]);

  const save = async () => {
    if (!title.trim() || !when) return toast.error("Add a name and a time.");
    setBusy(true);
    try {
      await createAlarm({ title: title.trim(), fire_at: new Date(when).toISOString(), note: note.trim() || null, task_id: prefill.task_id || null });
      toast.success(`Alarm set for ${fmtAlarmTime(new Date(when).toISOString())}`);
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
          <Input data-testid="alarm-time-input" type="datetime-local" value={when} onChange={(e) => setWhen(e.target.value)} />
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
        <div className="text-xs text-zinc-500">{fmtAlarmTime(a.fire_at)}{a.status === "fired" ? " · rang" : ""}</div>
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
