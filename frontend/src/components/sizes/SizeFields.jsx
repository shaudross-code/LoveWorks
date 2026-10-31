import { Input } from "@/components/ui/input";
import { CircleHelp } from "lucide-react";
import { lengthUnit, weightUnit, shoeFromUS, fmtNum, SHOE_SCALES, changeShoeScale, setNumeric, setHeightImperial } from "@/lib/sizes";

const label = "text-xs uppercase tracking-widest text-zinc-500";
const inputCls = "mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-12 text-base";
const hl = (on) => (on ? "ring-2 ring-pink-400/70 rounded-xl p-2 -m-2 bg-pink-400/5 transition" : "");

function FieldLabel({ field, onGuide }) {
  return (
    <div className="flex items-center gap-1.5">
      <label className={label}>{field.label}</label>
      {onGuide && (
        <button type="button" onClick={onGuide} aria-label={`How to measure ${field.label.toLowerCase()}`} data-testid={`guide-${field.k}`}
          className="inline-flex items-center gap-1 text-[10px] uppercase tracking-wider text-yellow-400/80 hover:text-yellow-300 transition">
          <CircleHelp className="w-3.5 h-3.5" /> How
        </button>
      )}
    </div>
  );
}

export function ChipRow({ field, value, onChange, highlight }) {
  return (
    <div className={hl(highlight)} data-testid={`size-field-${field.k}`}>
      <div className={label}>{field.label}</div>
      <div className="mt-2 flex flex-wrap gap-2">
        {field.options.map((o) => {
          const on = value === o;
          return (
            <button key={o} type="button" data-testid={`chip-${field.k}-${o.replace(/\s+/g, "-").toLowerCase()}`}
              onClick={() => onChange(on ? "" : o)}
              className={`min-h-10 px-3.5 rounded-full text-sm border transition ${
                on ? "bg-yellow-400 text-black border-yellow-400 font-semibold" : "border-yellow-400/20 text-zinc-300 hover:border-yellow-400/50 hover:text-white"
              }`}>
              {o}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export function NumberField({ field, value, units, onChange, highlight, onGuide }) {
  const unit = field.type === "weight" ? weightUnit(units) : lengthUnit(units);
  return (
    <div className={hl(highlight)} data-testid={`size-field-${field.k}`}>
      <FieldLabel field={field} onGuide={onGuide} />
      <div className="relative">
        <Input type="number" inputMode="decimal" step="0.1" min="0" value={value ?? ""} data-testid={`input-${field.k}`}
          onChange={(e) => onChange(e.target.value)} className={`${inputCls} pr-12`} placeholder="—" />
        <span className="absolute right-4 top-1/2 -translate-y-1/2 mt-1 text-xs text-zinc-500">{unit}</span>
      </div>
    </div>
  );
}

export function TextField({ field, value, onChange, highlight }) {
  const area = field.type === "textarea";
  const cls = `${inputCls} ${area ? "h-auto min-h-[96px] py-3 w-full resize-y" : ""}`;
  return (
    <div className={hl(highlight)} data-testid={`size-field-${field.k}`}>
      <label className={label}>{field.label}</label>
      {area
        ? <textarea value={value ?? ""} maxLength={1000} onChange={(e) => onChange(e.target.value)} placeholder={field.placeholder}
            data-testid={`input-${field.k}`} className={`${cls} border rounded-xl px-3 text-sm placeholder:text-zinc-600 focus:outline-none focus:ring-1 focus:ring-yellow-400/40`} />
        : <Input value={value ?? ""} maxLength={60} onChange={(e) => onChange(e.target.value)} placeholder={field.placeholder}
            data-testid={`input-${field.k}`} className={cls} />}
    </div>
  );
}

export function HeightField({ field, form, setForm, units, highlight, onGuide }) {
  if (units === "metric") {
    return <NumberField field={field} value={form.values.height ?? ""} units={units} highlight={highlight} onGuide={onGuide}
      onChange={(raw) => setForm(setNumeric(form, "height", raw, units))} />;
  }
  const ft = form.values.height_ft ?? "", inch = form.values.height_in ?? "";
  const box = "bg-zinc-900 border-zinc-800 text-white rounded-xl h-12 text-base pr-9";
  return (
    <div className={hl(highlight)} data-testid="size-field-height">
      <FieldLabel field={field} onGuide={onGuide} />
      <div className="mt-2 flex gap-2">
        <div className="relative flex-1">
          <Input type="number" inputMode="numeric" step="1" min="0" max="8" value={ft} data-testid="input-height_ft" placeholder="—"
            onChange={(e) => setForm(setHeightImperial(form, e.target.value, inch))} className={box} />
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-zinc-500">ft</span>
        </div>
        <div className="relative flex-1">
          <Input type="number" inputMode="decimal" step="0.5" min="0" max="11.5" value={inch} data-testid="input-height_in" placeholder="—"
            onChange={(e) => setForm(setHeightImperial(form, ft, e.target.value))} className={box} />
          <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-zinc-500">in</span>
        </div>
      </div>
      {Number.isFinite(form.canon?.height) && (
        <div className="mt-1.5 text-xs text-zinc-500" data-testid="height-equivalent">{fmtNum(form.canon.height)} cm</div>
      )}
    </div>
  );
}

export function ShoeField({ field, form, setForm, units, highlight }) {
  const raw = form.values.shoe_us ?? "";
  const eq = Number.isFinite(form.canon?.shoe_us) ? shoeFromUS(form.canon.shoe_us, form.fit) : null;
  return (
    <div className={hl(highlight)} data-testid="size-field-shoe_us">
      <label className={label}>{field.label}</label>
      <div className="mt-2 flex gap-2">
        <Input type="number" inputMode="decimal" step="0.5" min="0" value={raw} data-testid="input-shoe_us"
          onChange={(e) => setForm(setNumeric(form, "shoe_us", e.target.value, units))}
          className="bg-zinc-900 border-zinc-800 text-white rounded-xl h-12 text-base w-28" placeholder="—" />
        <div className="flex rounded-xl border border-zinc-800 bg-zinc-900 p-1 gap-1">
          {SHOE_SCALES.map((s) => (
            <button key={s} type="button" data-testid={`shoe-scale-${s.toLowerCase()}`} onClick={() => setForm(changeShoeScale(form, s))}
              className={`px-3 rounded-lg text-xs font-semibold transition ${form.shoeScale === s ? "bg-yellow-400 text-black" : "text-zinc-400 hover:text-white"}`}>
              {s}
            </button>
          ))}
        </div>
      </div>
      {eq && (
        <div className="mt-1.5 text-xs text-zinc-500" data-testid="shoe-equivalents">
          {SHOE_SCALES.filter((s) => s !== form.shoeScale).map((s) => `${s} ${fmtNum(eq[s])}`).join(" · ")}
        </div>
      )}
    </div>
  );
}
