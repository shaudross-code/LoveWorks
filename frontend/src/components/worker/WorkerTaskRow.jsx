import { AlarmClock, BadgeDollarSign, Calendar, CheckCircle2, Circle, Clock, Hourglass, Repeat, Wallet } from "lucide-react";
import { Button } from "@/components/ui/button";
import SpeakButton from "@/components/SpeakButton";
import { openAlarmDialog } from "@/lib/alarms";
import { fmtDailyHours, fmtDateDay, fmtTime12 } from "@/lib/format";

const DOW_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const CHIP = "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest";

function TaskTitleLine({ t, done }) {
  return (
    <div className="flex items-center gap-2 flex-wrap">
      <div className={`font-medium ${done ? "line-through text-zinc-500" : ""}`}>{t.title}</div>
      <SpeakButton testid={`speak-task-${t.id}`} text={`${t.title}. ${t.description || ""}`} label="Read task aloud" size={14} />
      {!done && (
        <button data-testid={`alarm-task-${t.id}`} aria-label="Set alarm for this task"
          onClick={() => openAlarmDialog({ title: t.title, task_id: t.id, due_time: t.due_time })}
          className="w-7 h-7 rounded-full grid place-items-center text-zinc-500 hover:text-yellow-400 hover:bg-yellow-400/10 transition-colors">
          <AlarmClock className="w-3.5 h-3.5" />
        </button>
      )}
      {t.frequency && t.frequency !== "once" && <span className={`${CHIP} bg-sky-400/15 text-sky-300`}><Repeat className="w-3 h-3" /> {t.frequency}</span>}
      {t.payout_schedule && t.payout_schedule !== "per_task" && (
        <span className={`${CHIP} bg-emerald-400/15 text-emerald-300`}><Wallet className="w-3 h-3" /> paid {t.payout_schedule}</span>
      )}
    </div>
  );
}

function TaskWhen({ t }) {
  return (
    <div className="text-xs text-zinc-500 mt-1 flex flex-wrap gap-x-3 gap-y-1 items-center">
      {t.due_at && <span><Calendar className="inline w-3 h-3 -mt-0.5" /> {fmtDateDay(t.due_at)}</span>}
      {t.due_day_of_week != null && <span><Calendar className="inline w-3 h-3 -mt-0.5" /> {DOW_NAMES[t.due_day_of_week]}</span>}
      {t.due_time && <span className="text-yellow-300"><Clock className="inline w-3 h-3 -mt-0.5" /> by {fmtTime12(t.due_time)}</span>}
      {t.daily_hours != null && <span><Hourglass className="inline w-3 h-3 -mt-0.5" /> {fmtDailyHours(t.daily_hours)}</span>}
      {t.estimated_hours != null && <span><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.estimated_hours}h total</span>}
    </div>
  );
}

// One task on the worker dashboard: tick to complete, Start to mark in progress.
export default function WorkerTaskRow({ t, onToggle, onStart }) {
  const done = t.status === "completed";
  return (
    <div data-testid={`worker-task-${t.id}`} className="px-5 sm:px-6 py-4 flex items-center gap-3 flex-wrap">
      <button data-testid={`toggle-task-${t.id}`} onClick={onToggle}
        className={`w-9 h-9 rounded-full grid place-items-center border transition ${done ? "bg-green-500/20 border-green-400/40 text-green-400" : "bg-zinc-900 border-yellow-400/20 text-zinc-500 hover:text-yellow-400"}`}>
        {done ? <CheckCircle2 className="w-5 h-5" /> : <Circle className="w-5 h-5" />}
      </button>
      <div className="flex-1 min-w-[200px]">
        <TaskTitleLine t={t} done={done} />
        {t.description && (
          <div data-testid={`worker-task-desc-${t.id}`} className="text-sm text-zinc-300 mt-1.5 whitespace-pre-wrap break-words">{t.description}</div>
        )}
        <TaskWhen t={t} />
      </div>
      <div className="inline-flex items-center gap-1 text-yellow-400 font-display font-semibold">
        <BadgeDollarSign className="w-4 h-4" />{Number(t.price).toFixed(2)}
      </div>
      {!done && (
        <Button data-testid={`worker-start-${t.id}`} size="sm" variant="ghost" onClick={onStart}
          className={`rounded-full h-8 px-3 text-xs border ${t.status === "in_progress" ? "border-yellow-400/30 text-yellow-300 bg-yellow-400/10" : "border-yellow-400/20 text-zinc-300 hover:text-yellow-400"}`}>
          {t.status === "in_progress" ? "Working…" : "Start"}
        </Button>
      )}
    </div>
  );
}
