import { CheckCircle2, Pencil, Trash2, UserCircle2 } from "lucide-react";
import { fileUrl } from "@/lib/api";
import { catOf, lineTotal } from "@/lib/essentials";
import { fmtDateShort } from "@/lib/format";

const CHIP = "inline-flex items-center gap-1 px-2 py-0.5 rounded-full";

function EssentialTags({ it }) {
  return (
    <div className="mt-1.5 flex flex-wrap gap-1.5 text-[10px] uppercase tracking-widest">
      <span className={`${CHIP} border ${it.recurring ? "bg-emerald-400/10 text-emerald-300 border-emerald-400/30" : "bg-pink-400/10 text-pink-300 border-pink-400/30"}`}>
        {it.recurring ? "🔁 recurring" : "✨ one-time"}
      </span>
      {it.due_date && <span className={`${CHIP} bg-amber-400/10 text-amber-300 border border-amber-400/30`}>📅 due {fmtDateShort(it.due_date)}</span>}
      {it.completed_at && <span className={`${CHIP} bg-emerald-500/10 text-emerald-300 border border-emerald-400/30`}>✓ {fmtDateShort(it.completed_at)}</span>}
    </div>
  );
}

function RoundButton({ testid, onClick, title, className, children }) {
  return (
    <button data-testid={testid} onClick={onClick} title={title}
      className={`w-8 h-8 rounded-full grid place-items-center transition ${className}`}>
      {children}
    </button>
  );
}

// One essentials item: photo, category, price × quantity, bought toggle, edit and remove.
export default function EssentialCard({ it, onToggle, onEdit, onDelete }) {
  const cat = catOf(it.category);
  return (
    <div data-testid={`essential-${it.id}`}
      className={`rounded-2xl border bg-[#121214] p-4 flex gap-4 ${it.purchased ? "border-emerald-400/30 opacity-70" : "border-yellow-400/10 hover:border-yellow-400/30"} transition`}>
      <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/10 grid place-items-center shrink-0">
        {it.image_url ? <img src={fileUrl(it.image_url)} alt={`Photo of ${it.title}`} className="w-full h-full object-cover" />
          : <cat.icon className="w-8 h-8 text-zinc-700" />}
      </div>
      <div className="flex-1 min-w-0 flex flex-col">
        <div className="flex items-start gap-2 flex-wrap">
          <span className={`${CHIP} text-[10px] uppercase tracking-widest border ${cat.color}`}><cat.icon className="w-3 h-3" /> {cat.label}</span>
          {it.owner && (
            <span className={`${CHIP} text-[10px] uppercase tracking-widest bg-zinc-800 text-zinc-400`}>
              <UserCircle2 className="w-3 h-3" /> {it.owner.name || it.owner.email}
            </span>
          )}
        </div>
        <div className={`mt-1 font-display font-semibold text-lg leading-tight ${it.purchased ? "line-through text-zinc-500" : ""}`}>{it.title}</div>
        {it.note && <div className="text-xs text-zinc-500 mt-0.5">{it.note}</div>}
        <EssentialTags it={it} />
        <div className="mt-auto pt-3 flex items-end justify-between gap-3 flex-wrap">
          <div className="flex items-baseline gap-2 tabular-nums">
            <span className={`font-display font-bold text-2xl ${it.purchased ? "text-zinc-400" : "text-yellow-400"}`}>${lineTotal(it).toFixed(2)}</span>
            <span className="text-xs text-zinc-500">${Number(it.price || 0).toFixed(2)} × {it.quantity || 1}</span>
          </div>
          <div className="flex items-center gap-1.5">
            <RoundButton testid={`toggle-purchased-${it.id}`} onClick={onToggle} title={it.purchased ? "Mark as needed again" : "Mark as bought"}
              className={it.purchased ? "bg-emerald-400/15 text-emerald-400 hover:bg-emerald-400/25" : "bg-zinc-800 text-zinc-400 hover:bg-zinc-700 hover:text-emerald-400"}>
              <CheckCircle2 className="w-4 h-4" />
            </RoundButton>
            <RoundButton testid={`edit-essential-${it.id}`} onClick={onEdit} className="bg-zinc-800 text-zinc-400 hover:text-yellow-400">
              <Pencil className="w-4 h-4" />
            </RoundButton>
            <RoundButton testid={`delete-essential-${it.id}`} onClick={onDelete} className="bg-zinc-800 text-zinc-400 hover:text-red-400 hover:bg-red-500/10">
              <Trash2 className="w-4 h-4" />
            </RoundButton>
          </div>
        </div>
      </div>
    </div>
  );
}
