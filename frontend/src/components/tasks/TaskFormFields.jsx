import LabeledInput, { FieldLabel } from "@/components/form/LabeledInput";
import LabeledSelect from "@/components/form/LabeledSelect";
import { DAYS_OF_WEEK, FREQUENCIES, PAYOUTS } from "@/lib/tasks";

const DOW_OPTIONS = [{ value: "none", label: "No specific day" }, ...DAYS_OF_WEEK];

// Deadline date, due time and due weekday.
export function TaskScheduleFields({ form, setForm, field }) {
  const dowHint = `${form.frequency === "weekly" ? "Repeats every week on this day. " : "Shown on the task card so the crew knows the day. "}e.g., Friday by 6 PM = pick Friday + set Due time 18:00.`;
  return (
    <>
      <div className="grid grid-cols-2 gap-3">
        <LabeledInput label="Deadline date" testid="task-due-at" type="date" className="[color-scheme:dark]"
          hint="For one-time tasks. Recurring tasks ignore this." {...field("due_at")} />
        <LabeledInput label="Due time" testid="task-due-time" type="time" className="[color-scheme:dark]"
          hint="e.g., 18:00 = by 6 PM" {...field("due_time")} />
      </div>
      <LabeledSelect label="Due day of the week" testid="task-due-dow" placeholder="Pick a day…" options={DOW_OPTIONS}
        optionPrefix="dow" hint={dowHint} value={form.due_day_of_week || "none"}
        onValue={(v) => setForm((f) => ({ ...f, due_day_of_week: v === "none" ? "" : v }))} />
    </>
  );
}

function UnitToggle({ unit, onChange }) {
  return (
    <div className="inline-flex items-center bg-zinc-900 border border-zinc-800 rounded-full p-0.5 shrink-0">
      {["hours", "minutes"].map((u) => (
        <button key={u} type="button" data-testid={`unit-${u}`} onClick={() => onChange(u)}
          className={`px-3 py-1 rounded-full text-[10px] uppercase tracking-widest transition ${unit === u ? "bg-yellow-400 text-black font-semibold" : "text-zinc-400 hover:text-white"}`}>
          {u === "hours" ? "Hours" : "Minutes"}
        </button>
      ))}
    </div>
  );
}

function DailyHoursField({ form, setForm }) {
  const minutes = form.daily_hours_unit === "minutes";
  return (
    <div>
      <div className="flex items-center justify-between gap-2 flex-wrap">
        <FieldLabel>Daily required</FieldLabel>
        <UnitToggle unit={form.daily_hours_unit} onChange={(u) => setForm((f) => ({ ...f, daily_hours_unit: u }))} />
      </div>
      <LabeledInput testid="task-daily-hours" type="number" min="0" step="any" inputMode="decimal"
        placeholder={minutes ? "e.g., 45" : "e.g., 1.5"} hint="Stored internally as hours · 45 min = 0.75h"
        value={form.daily_hours} onValue={(v) => setForm((f) => ({ ...f, daily_hours: v }))} />
    </div>
  );
}

// Estimated hours, daily requirement, frequency and payout schedule.
export function TaskEffortFields({ form, setForm, field }) {
  return (
    <>
      <LabeledInput label="Total est. hours" testid="task-estimated-hours" type="number" min="0" step="any" inputMode="decimal"
        placeholder="e.g., 3.33" hint="Any decimal — 3.33, 7.5, 0.25, anything." {...field("estimated_hours")} />
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <DailyHoursField form={form} setForm={setForm} />
        <LabeledSelect label="Frequency" testid="task-frequency" options={FREQUENCIES} optionPrefix="freq" {...field("frequency")} />
      </div>
      <LabeledSelect label="Payout schedule" testid="task-payout" options={PAYOUTS} optionPrefix="payout" hintClassName="text-xs text-zinc-500 mt-1.5"
        hint={<><span className="text-zinc-400">On completion</span> = pay when worker marks done · <span className="text-zinc-400">Daily/Weekly/Monthly</span> = recurring payout.</>}
        {...field("payout_schedule")} />
    </>
  );
}
