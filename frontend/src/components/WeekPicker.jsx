import { ChevronLeft, ChevronRight, CalendarDays } from "lucide-react";
import { shiftWeek, weekRange } from "@/lib/weeks";

export default function WeekPicker({ data, onChange, testid = "week-picker" }) {
  if (!data) return null;
  const btn = "w-9 h-9 grid place-items-center rounded-full border border-yellow-400/20 text-zinc-300 hover:border-yellow-400/60 hover:text-yellow-300 transition-colors disabled:opacity-30 disabled:pointer-events-none";
  return (
    <div data-testid={testid} className="inline-flex items-center gap-2">
      <button data-testid={`${testid}-prev`} className={btn} onClick={() => onChange(shiftWeek(data.week_start, -1))} aria-label="Previous week">
        <ChevronLeft className="w-4 h-4" />
      </button>
      <div className="px-4 h-9 rounded-full bg-zinc-900/70 border border-zinc-800 inline-flex items-center gap-2 text-sm min-w-[190px] justify-center">
        <CalendarDays className="w-4 h-4 text-yellow-400" />
        <span data-testid={`${testid}-label`} className="font-medium tabular-nums">{weekRange(data.week_start, data.week_last_day)}</span>
        {data.is_current && <span className="text-[10px] uppercase tracking-widest text-yellow-400">this week</span>}
      </div>
      <button data-testid={`${testid}-next`} className={btn} disabled={data.is_current || data.is_future} onClick={() => onChange(shiftWeek(data.week_start, 1))} aria-label="Next week">
        <ChevronRight className="w-4 h-4" />
      </button>
      {!data.is_current && (
        <button data-testid={`${testid}-today`} onClick={() => onChange(null)} className="text-xs text-yellow-300 hover:text-yellow-200 px-2 transition-colors">This week</button>
      )}
    </div>
  );
}
