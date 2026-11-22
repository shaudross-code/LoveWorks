import { BadgeDollarSign, Calendar, Link as LinkIcon, Percent } from "lucide-react";
import LabeledInput from "@/components/form/LabeledInput";
import LabeledSelect from "@/components/form/LabeledSelect";
import { PERIODS } from "@/lib/wishlist";

// Goal/trip form inputs; testids follow `${prefix}-<field>` (goal-, assign-, edit-).

export function TargetInput({ prefix, field, placeholder = "e.g., 200" }) {
  return (
    <LabeledInput label="Target amount" icon={BadgeDollarSign} testid={`${prefix}-target`} type="number" min="0"
      step="any" inputMode="decimal" placeholder={placeholder} {...field("target_amount")} />
  );
}

export function PeriodSelect({ prefix, field }) {
  return <LabeledSelect label="Period" testid={`${prefix}-period`} options={PERIODS} optionPrefix={`${prefix}-period`} {...field("period")} />;
}

export function AllocationInput({ prefix, field, label = "Allocation %", hint }) {
  return (
    <LabeledInput label={label} icon={Percent} testid={`${prefix}-allocation`} type="number" min="0" max="100"
      step="any" inputMode="decimal" placeholder="e.g., 50" hint={hint} {...field("allocation_percent")} />
  );
}

export function DeadlineInput({ prefix, field, label = "Deadline (optional)" }) {
  return (
    <LabeledInput label={label} icon={Calendar} testid={`${prefix}-deadline`} type="date"
      className="[color-scheme:dark]" {...field("deadline")} />
  );
}

export function LinkInput({ prefix, field, label, icon = LinkIcon }) {
  return (
    <LabeledInput label={label} icon={icon} testid={`${prefix}-link`} type="url" placeholder="https://…" {...field("product_link")} />
  );
}
