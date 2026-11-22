import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { FIELD_INPUT, FieldHint, FieldLabel } from "@/components/form/LabeledInput";

// options: [{ value, label }]; optionPrefix gives each item data-testid `${optionPrefix}-${value}`.
export default function LabeledSelect({ label, icon, testid, value, onValue, options, optionPrefix, placeholder, hint, hintClassName }) {
  return (
    <div>
      <FieldLabel icon={icon}>{label}</FieldLabel>
      <Select value={value} onValueChange={onValue}>
        <SelectTrigger data-testid={testid} className={FIELD_INPUT}>
          <SelectValue placeholder={placeholder} />
        </SelectTrigger>
        <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
          {options.map((o) => (
            <SelectItem key={o.value} value={o.value} data-testid={optionPrefix ? `${optionPrefix}-${o.value}` : undefined}>
              {o.label}
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      <FieldHint className={hintClassName}>{hint}</FieldHint>
    </div>
  );
}
