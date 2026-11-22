import { useCallback, useEffect, useRef, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { AlarmClock, BellOff, Timer } from "lucide-react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { listAlarms, snoozeAlarm, dismissAlarm, announceAlarmsChanged, fmtAlarmTime, ALARMS_CHANGED } from "@/lib/alarms";

const DAY_MS = 24 * 60 * 60 * 1000;

// Looping two-tone beep via Web Audio; returns a stop function.
function startBeeping() {
  try {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    let on = true;
    const beep = () => {
      if (!on) return;
      [0, 0.25].forEach((t, i) => {
        const o = ctx.createOscillator(); const g = ctx.createGain();
        o.frequency.value = i ? 660 : 880; g.gain.value = 0.15;
        o.connect(g); g.connect(ctx.destination);
        o.start(ctx.currentTime + t); o.stop(ctx.currentTime + t + 0.18);
      });
      navigator.vibrate?.([200, 100, 200]);
    };
    beep();
    const id = setInterval(beep, 1200);
    return () => { on = false; clearInterval(id); ctx.close().catch(() => {}); };
  } catch { return () => {}; }
}

function RingDialog({ alarm, onSnooze, onStop }) {
  return (
    <Dialog open={!!alarm} onOpenChange={(o) => !o && onStop()}>
      <DialogContent data-testid="alarm-ring-dialog" className="bg-[#121214] border-yellow-400/40 text-white">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-xl"><AlarmClock className="w-6 h-6 text-yellow-400 animate-pulse" /> {alarm?.title}</DialogTitle>
        </DialogHeader>
        <div className="text-sm text-zinc-400">{alarm?.note || "Your alarm is ringing."} · {alarm && fmtAlarmTime(alarm.fire_at)}</div>
        <div className="mt-4 flex gap-2">
          <button data-testid="alarm-snooze-btn" onClick={onSnooze} className="flex-1 inline-flex items-center justify-center gap-2 h-11 rounded-full border border-yellow-400/30 text-yellow-300 hover:bg-yellow-400/10 transition-colors"><Timer className="w-4 h-4" /> Snooze 10 min</button>
          <button data-testid="alarm-stop-btn" onClick={onStop} className="flex-1 inline-flex items-center justify-center gap-2 h-11 rounded-full bg-yellow-400 hover:bg-yellow-300 text-black font-semibold transition-colors"><BellOff className="w-4 h-4" /> Stop</button>
        </div>
      </DialogContent>
    </Dialog>
  );
}

export default function AlarmWatcher() {
  const [ringing, setRinging] = useState(null);
  const timers = useRef([]);
  const rung = useRef(new Set()); // `${id}@${fire_at}` already rung this session
  const stopSound = useRef(() => {});
  const nav = useNavigate();
  const { search, pathname } = useLocation();

  const ring = useCallback((a, sound = true) => {
    rung.current.add(`${a.id}@${a.fire_at}`);
    stopSound.current();
    stopSound.current = sound ? startBeeping() : () => {};
    setRinging(a);
  }, []);

  const schedule = useCallback(async () => {
    timers.current.forEach(clearTimeout);
    timers.current = [];
    const alarms = await listAlarms().catch(() => []);
    const now = Date.now();
    alarms.filter((a) => a.status === "scheduled" && !rung.current.has(`${a.id}@${a.fire_at}`)).forEach((a) => {
      const delta = new Date(a.fire_at).getTime() - now;
      if (delta > -60000 && delta < DAY_MS) timers.current.push(setTimeout(() => ring(a), Math.max(0, delta)));
    });
    return alarms;
  }, [ring]);

  useEffect(() => {
    schedule();
    const onVis = () => document.visibilityState === "visible" && schedule();
    const tick = setInterval(schedule, 60000);
    window.addEventListener(ALARMS_CHANGED, schedule);
    document.addEventListener("visibilitychange", onVis);
    // Service worker asks us to route after a notification tap
    const onMsg = (e) => e.data?.type === "navigate" && e.data.link && nav(e.data.link);
    navigator.serviceWorker?.addEventListener("message", onMsg);
    return () => {
      clearInterval(tick); timers.current.forEach(clearTimeout); stopSound.current();
      window.removeEventListener(ALARMS_CHANGED, schedule);
      document.removeEventListener("visibilitychange", onVis);
      navigator.serviceWorker?.removeEventListener("message", onMsg);
    };
  }, [schedule, nav]);

  // Opened from an alarm notification: /worker?alarm=<id>
  useEffect(() => {
    const id = new URLSearchParams(search).get("alarm");
    if (!id) return;
    listAlarms().then((list) => { const a = list.find((x) => x.id === id); if (a) ring(a, false); }).catch(() => {});
    nav(pathname, { replace: true });
  }, [search, pathname, nav, ring]);

  const close = async (snooze) => {
    stopSound.current();
    const a = ringing;
    setRinging(null);
    if (!a) return;
    try { if (snooze) await snoozeAlarm(a.id, 10); else await dismissAlarm(a.id); } catch { /* noop */ }
    announceAlarmsChanged();
  };

  return <RingDialog alarm={ringing} onSnooze={() => close(true)} onStop={() => close(false)} />;
}
