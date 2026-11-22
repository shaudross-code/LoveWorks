import { Input } from "@/components/ui/input";

export const FIELD_INPUT = "mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11";

export function FieldLabel({ icon: Icon, children }) {
  if (!Icon) return <label className="text-xs uppercase tracking-widest text-zinc-500">{children}</label>;
  return (
    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1">
      <Icon className="w-3 h-3" /> {children}
    </label>
  );
}

export function FieldHint({ children, className = "text-[10px] text-zinc-500 mt-1" }) {
  return children ? <div className={className}>{children}</div> : null;
}

export default function LabeledInput({ label, icon, testid, value, onValue, hint, hintClassName, className = "", ...rest }) {
  return (
    <div>
      {label && <FieldLabel icon={icon}>{label}</FieldLabel>}
      <Input data-testid={testid} value={value} onChange={(e) => onValue(e.target.value)}
        className={`${FIELD_INPUT} ${className}`} {...rest} />
      <FieldHint className={hintClassName}>{hint}</FieldHint>
    </div>
  );
}
