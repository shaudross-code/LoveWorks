import { useState } from "react";
import { Loader2, Play, Plus, Square, TrendingUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { ActiveClocks, ActivityPicker, Tile } from "@/components/worker/ClockPanels";
import { useNow } from "@/hooks/useNow";
import { activityOf } from "@/lib/activities";
import { todayHours } from "@/lib/deadlines";
import { fmtClock } from "@/lib/format";

function Headline({ actives }) {
  return (
    <>
      <div className="text-xs uppercase tracking-widest text-yellow-400 flex items-center gap-2 flex-wrap">
        {actives.length > 0 ? (
          <>
            Currently
            {actives.map((a) => {
              const act = activityOf(a.activity);
              return (
                <span key={a.id} data-testid={`active-pill-${a.activity}`} className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] ${act.pill}`}>
                  <act.icon className="w-3 h-3" /> {act.label}
                </span>
              );
            })}
          </>
        ) : "Ready to start"}
      </div>
      <h1 className="font-display text-3xl sm:text-5xl font-bold tracking-tight mt-2">
        {actives.length > 1 ? `You're juggling ${actives.length} clocks.` : actives.length === 1 ? "You're on the clock." : "Punch in to begin."}
      </h1>
    </>
  );
}

function ClockRing({ primary, seconds, busy, onTogglePicker, onClockOutAll }) {
  if (!primary) {
    return (
      <Button data-testid="clock-in-btn" disabled={busy} onClick={onTogglePicker}
        className="h-36 w-36 sm:h-44 sm:w-44 rounded-full bg-yellow-400 hover:bg-yellow-300 text-black font-display font-bold text-lg sm:text-xl shadow-xl shadow-yellow-400/30 gold-pulse transition-transform hover:scale-105">
        <div className="flex flex-col items-center"><Play className="w-9 h-9 mb-1" /> Clock in</div>
      </Button>
    );
  }
  const act = activityOf(primary.activity);
  return (
    <div className="flex flex-col items-center gap-3">
      <div className={`relative h-36 w-36 sm:h-44 sm:w-44 rounded-full ${act.bg} grid place-items-center shadow-xl ${act.text} ring-4 ${act.ring}`}>
        <div className="text-center">
          <act.icon className="w-7 h-7 mx-auto" />
          <div className="font-display font-bold mt-1 text-sm uppercase tracking-widest">{act.label}</div>
          <div className="font-display font-bold tabular-nums text-lg mt-1">{fmtClock(seconds)}</div>
        </div>
      </div>
      <div className="flex flex-wrap gap-2 justify-center">
        <Button data-testid="add-clock-btn" disabled={busy} onClick={onTogglePicker} className="rounded-full h-10 px-4 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold">
          <Plus className="w-4 h-4 mr-1.5" /> Start another
        </Button>
        <Button data-testid="clock-out-btn" disabled={busy} onClick={onClockOutAll} className="rounded-full h-10 px-4 bg-red-500 hover:bg-red-400 text-white font-semibold">
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Square className="w-4 h-4 mr-1.5" /> Clock out all</>}
        </Button>
      </div>
    </div>
  );
}

// Clock-in hero: live timers, today's tiles, the big clock button and the activity picker.
export default function ClockHero({ dash }) {
  const { actives, entries, weekly, deadlines: dl, groups, busy, clockIn, clockOut } = dash;
  const now = useNow();
  const [pickerOpen, setPickerOpen] = useState(false);
  const primary = actives[0] || null;
  const liveSeconds = primary ? (now - new Date(primary.clock_in).getTime()) / 1000 : 0;
  const pick = async (key) => { if (await clockIn(key)) setPickerOpen(false); };
  const togglePicker = () => setPickerOpen((v) => !v);

  return (
    <div className="relative overflow-hidden bg-[#121214] border border-yellow-400/15 rounded-3xl p-5 sm:p-10">
      <div className="absolute -top-32 -right-32 w-[420px] h-[420px] bg-yellow-400/10 rounded-full blur-3xl pointer-events-none" />
      <div className="relative grid lg:grid-cols-[1fr_auto] gap-8 items-center">
        <div className="min-w-0">
          <Headline actives={actives} />
          <div className="mt-6 grid grid-cols-2 sm:grid-cols-3 gap-3 max-w-2xl">
            <Tile testid="shift-timer" label={actives.length > 1 ? "Earliest timer" : "Shift timer"} value={primary ? fmtClock(liveSeconds) : "00:00:00"} />
            <Tile testid="today-hours" label="Today" value={`${todayHours(entries, actives, now).toFixed(2)}h`} />
            <Tile testid="open-task-count" label="Open tasks" value={groups.open.length} />
            <Tile testid="earnings-total" label="Earned this week" value={`$${Number(weekly.week_earned || 0).toFixed(2)}`} accent="text-yellow-400" />
            <Tile testid="weekly-potential" label="This week potential" value={`$${dl.weeklyPotential.toFixed(2)}`} accent="text-yellow-400" icon={TrendingUp}
              sub={`if you finish ${dl.dueThisWeek.length + dl.dueToday.length} due tasks`} />
            <Tile testid="open-total" label="All open value" value={`$${dl.openTotal.toFixed(2)}`} sub="across all open tasks" />
          </div>
        </div>
        <div className="flex justify-center lg:justify-end">
          <ClockRing primary={primary} seconds={liveSeconds} busy={busy} onTogglePicker={togglePicker} onClockOutAll={() => clockOut()} />
        </div>
      </div>
      {actives.length > 0 && <ActiveClocks actives={actives} now={now} busy={busy} onStop={clockOut} />}
      {pickerOpen && <ActivityPicker actives={actives} busy={busy} onPick={pick} />}
    </div>
  );
}
