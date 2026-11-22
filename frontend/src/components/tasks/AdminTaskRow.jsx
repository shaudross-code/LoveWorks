import { AlarmClock, BadgeDollarSign, Calendar, Clock, Hourglass, Pencil, Repeat, Trash2, Wallet } from "lucide-react";
import { Button } from "@/components/ui/button";
import SpeakButton from "@/components/SpeakButton";
import { alarmLabel } from "@/components/TaskAlarmFields";
import { fmtDailyHours, fmtDateShort, fmtTime12 } from "@/lib/format";
import { DOW_LABEL, FREQ_LABEL, PAYOUT_LABEL, STATUS_STYLE } from "@/lib/tasks";

function TaskBadges({ t }) {
  return (
    <>
      <span className={`px-2.5 py-0.5 rounded-full text-xs ${STATUS_STYLE[t.status]}`}>{t.status.replace("_", " ")}</span>
      {t.frequency && t.frequency !== "once" && (
        <span className="px-2.5 py-0.5 rounded-full text-xs bg-sky-400/15 text-sky-300 inline-flex items-center gap-1">
          <Repeat className="w-3 h-3" /> {FREQ_LABEL[t.frequency]}
        </span>
      )}
      {t.payout_schedule && t.payout_schedule !== "per_task" && (
        <span className="px-2.5 py-0.5 rounded-full text-xs bg-emerald-400/15 text-emerald-300 inline-flex items-center gap-1">
          <Wallet className="w-3 h-3" /> Paid {PAYOUT_LABEL[t.payout_schedule].toLowerCase()}
        </span>
      )}
    </>
  );
}

function TaskMeta({ t }) {
  return (
    <div className="text-xs text-zinc-500 mt-1 flex flex-wrap items-center gap-x-3 gap-y-1">
      <span>{t.assignee_name}</span>
      {t.due_at && <span className="text-zinc-400"><Calendar className="inline w-3 h-3 -mt-0.5" /> {fmtDateShort(t.due_at)}</span>}
      {t.due_day_of_week != null && <span className="text-zinc-400"><Calendar className="inline w-3 h-3 -mt-0.5" /> {DOW_LABEL[String(t.due_day_of_week)]}</span>}
      {t.due_time && <span className="text-yellow-300"><Clock className="inline w-3 h-3 -mt-0.5" /> by {fmtTime12(t.due_time)}</span>}
      {t.alarm && <span data-testid={`task-alarm-badge-${t.id}`} className="text-yellow-400"><AlarmClock className="inline w-3 h-3 -mt-0.5" /> {alarmLabel(t.alarm)}</span>}
      {t.estimated_hours != null && <span className="text-zinc-400"><Hourglass className="inline w-3 h-3 -mt-0.5" /> {t.estimated_hours}h total</span>}
      {t.daily_hours != null && <span className="text-zinc-400"><Hourglass className="inline w-3 h-3 -mt-0.5" /> {fmtDailyHours(t.daily_hours)}</span>}
    </div>
  );
}

// One task on the admin workboard.
export default function AdminTaskRow({ t, onEdit, onComplete, onDelete }) {
  return (
    <div data-testid={`task-row-${t.id}`} className="px-5 sm:px-6 py-4 flex items-center gap-3 flex-wrap hover:bg-white/[0.02]">
      <div className="flex-1 min-w-[260px]">
        <div className="flex items-center gap-2 flex-wrap">
          <div className="font-medium">{t.title}</div>
          <SpeakButton testid={`speak-task-${t.id}`} text={`${t.title}. ${t.description || ""}`} label="Read task aloud" size={14} />
          <TaskBadges t={t} />
        </div>
        {t.description && (
          <div data-testid={`task-desc-${t.id}`} className="text-sm text-zinc-300 mt-1.5 whitespace-pre-wrap break-words">{t.description}</div>
        )}
        <TaskMeta t={t} />
      </div>
      <div className="flex items-center gap-2">
        <div className="flex items-center bg-zinc-900 border border-zinc-800 rounded-lg px-2 h-9">
          <BadgeDollarSign className="w-3.5 h-3.5 text-yellow-400 mr-1" />
          <span data-testid={`task-price-${t.id}`} className="w-20 text-white text-sm">{Number(t.price).toFixed(2)}</span>
        </div>
        <Button data-testid={`edit-task-${t.id}`} onClick={onEdit} size="sm" variant="ghost"
          className="rounded-lg h-9 px-3 text-zinc-300 hover:text-yellow-400 border border-yellow-400/15">
          <Pencil className="w-4 h-4" />
        </Button>
        {t.status !== "completed" && (
          <Button data-testid={`mark-complete-${t.id}`} onClick={onComplete} size="sm"
            className="bg-green-500/20 hover:bg-green-500/30 text-green-400 border border-green-400/30 rounded-lg">
            Mark complete
          </Button>
        )}
        <button data-testid={`delete-task-${t.id}`} onClick={onDelete} className="text-zinc-500 hover:text-red-400 transition">
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
