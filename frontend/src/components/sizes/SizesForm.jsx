import { useState } from "react";
import { ChevronDown } from "lucide-react";
import { SECTIONS, FITS, sectionFields, completion, setNumeric, changeFit } from "@/lib/sizes";
import { ChipRow, NumberField, TextField, ShoeField, HeightField } from "./SizeFields";

export function UnitsToggle({ units, onChange }) {
  return (
    <div className="inline-flex rounded-full border border-yellow-400/20 bg-zinc-900 p-1" data-testid="units-toggle">
      {[["imperial", "in · lb · US"], ["metric", "cm · kg · EU"]].map(([v, l]) => (
        <button key={v} type="button" data-testid={`units-${v}`} onClick={() => onChange(v)}
          className={`px-3 h-8 rounded-full text-xs font-semibold transition ${units === v ? "bg-yellow-400 text-black" : "text-zinc-400 hover:text-white"}`}>
          {l}
        </button>
      ))}
    </div>
  );
}

export function FitPicker({ fit, onChange, highlight }) {
  return (
    <div data-testid="fit-picker" className={highlight ? "ring-2 ring-pink-400/70 rounded-xl p-2 -m-2 bg-pink-400/5 transition" : ""}>
      <div className="text-xs uppercase tracking-widest text-zinc-500">Fit</div>
      <div className="mt-2 flex flex-wrap gap-2">
        {FITS.map((f) => (
          <button key={f.v} type="button" data-testid={`fit-${f.v}`} onClick={() => onChange(f.v)}
            className={`min-h-10 px-4 rounded-full text-sm border transition ${
              fit === f.v ? "bg-pink-400 text-white border-pink-400 font-semibold" : "border-yellow-400/20 text-zinc-300 hover:border-pink-400/50"
            }`}>
            {f.label}
          </button>
        ))}
      </div>
      {!fit && <div className="mt-2 text-xs text-zinc-500">Pick a fit to show the right clothing and underclothes sizes.</div>}
    </div>
  );
}

function Field({ field, form, setForm, units, highlight }) {
  const set = (v) => setForm({ ...form, values: { ...form.values, [field.k]: v } });
  const value = form.values[field.k] ?? "";
  const on = highlight.includes(field.k);
  if (field.type === "chips") return <ChipRow field={field} value={value} onChange={set} highlight={on} />;
  if (field.type === "height") return <HeightField field={field} form={form} setForm={setForm} units={units} highlight={on} />;
  if (field.type === "shoe") return <ShoeField field={field} form={form} setForm={setForm} units={units} highlight={on} />;
  if (field.type === "length" || field.type === "weight") {
    return <NumberField field={field} value={value} units={units} onChange={(raw) => setForm(setNumeric(form, field.k, raw, units))} highlight={on} />;
  }
  return <TextField field={field} value={value} onChange={set} highlight={on} />;
}

function Section({ section, form, setForm, units, highlight, defaultOpen }) {
  const [open, setOpen] = useState(defaultOpen);
  const fields = sectionFields(section, form.fit);
  const { filled, total } = completion(section, form);
  return (
    <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl overflow-hidden" data-testid={`section-${section.key}`}>
      <button type="button" onClick={() => setOpen((o) => !o)} data-testid={`section-toggle-${section.key}`}
        className="w-full flex items-center gap-3 px-5 py-4 text-left hover:bg-white/[0.02] transition">
        <div className="flex-1 min-w-0">
          <div className="font-display text-lg font-semibold">{section.title}</div>
          <div className="text-xs text-zinc-500">{section.blurb}</div>
        </div>
        <span data-testid={`section-count-${section.key}`}
          className={`text-[11px] px-2 py-0.5 rounded-full border ${filled === total && total > 0 ? "bg-emerald-400/10 text-emerald-300 border-emerald-400/30" : "bg-zinc-900 text-zinc-400 border-zinc-800"}`}>
          {filled} of {total} filled
        </span>
        <ChevronDown className={`w-4 h-4 text-zinc-500 transition-transform ${open ? "rotate-180" : ""}`} />
      </button>
      {open && (
        <div className="px-5 pb-5 pt-1 grid gap-5 sm:grid-cols-2">
          {fields.map((f) => (
            <div key={`${f.k}-${(f.fits || []).join("")}`} className={f.type === "textarea" || f.type === "chips" ? "sm:col-span-2" : ""}>
              <Field field={f} form={form} setForm={setForm} units={units} highlight={highlight} />
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default function SizesForm({ form, setForm, units, highlight = [] }) {
  return (
    <div className="space-y-4">
      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-5">
        <FitPicker fit={form.fit} onChange={(fit) => setForm(changeFit(form, fit))} highlight={highlight.includes("fit")} />
      </div>
      {SECTIONS.map((s, i) => (
        <Section key={s.key} section={s} form={form} setForm={setForm} units={units} highlight={highlight}
          defaultOpen={i === 0 || sectionFields(s, form.fit).some((f) => highlight.includes(f.k))} />
      ))}
    </div>
  );
}
