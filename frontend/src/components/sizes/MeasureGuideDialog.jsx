import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { ChevronLeft, ChevronRight, Ruler } from "lucide-react";
import { GUIDE, guideIndex } from "@/lib/measureGuide";

export default function MeasureGuideDialog({ fieldKey, onChange, onClose }) {
  const idx = guideIndex(fieldKey);
  const item = GUIDE[idx];
  const go = (d) => onChange(GUIDE[(idx + d + GUIDE.length) % GUIDE.length].k);
  return (
    <Dialog open={!!item} onOpenChange={(o) => { if (!o) onClose(); }}>
      <DialogContent className="bg-[#09090B] border-yellow-400/20 text-white rounded-2xl max-w-md p-0 overflow-hidden" aria-describedby={undefined} data-testid="measure-guide-dialog">
        {item && (
          <>
            <div className="relative bg-[#121214]">
              <img src={item.img} alt={`Where to measure ${item.title.toLowerCase()}`} className="w-full aspect-square object-cover" data-testid="measure-guide-image" />
              <button type="button" onClick={() => go(-1)} aria-label="Previous" data-testid="measure-guide-prev"
                className="absolute left-2 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/60 border border-yellow-400/20 grid place-items-center text-zinc-300 hover:text-yellow-300 transition">
                <ChevronLeft className="w-5 h-5" />
              </button>
              <button type="button" onClick={() => go(1)} aria-label="Next" data-testid="measure-guide-next"
                className="absolute right-2 top-1/2 -translate-y-1/2 w-10 h-10 rounded-full bg-black/60 border border-yellow-400/20 grid place-items-center text-zinc-300 hover:text-yellow-300 transition">
                <ChevronRight className="w-5 h-5" />
              </button>
            </div>
            <div className="p-5">
              <div className="text-[10px] uppercase tracking-widest text-yellow-400 inline-flex items-center gap-1.5"><Ruler className="w-3 h-3" /> How to measure · {idx + 1} of {GUIDE.length}</div>
              <DialogTitle className="font-display text-2xl mt-1" data-testid="measure-guide-title">{item.title}</DialogTitle>
              <p className="mt-2 text-sm text-zinc-400 leading-relaxed" data-testid="measure-guide-tip">{item.tip}</p>
              <div className="mt-4 flex gap-1.5 flex-wrap">
                {GUIDE.map((g, i) => (
                  <button key={g.k} type="button" onClick={() => onChange(g.k)} aria-label={g.title} data-testid={`measure-guide-dot-${g.k}`}
                    className={`h-1.5 rounded-full transition-all ${i === idx ? "w-6 bg-yellow-400" : "w-1.5 bg-zinc-700 hover:bg-zinc-500"}`} />
                ))}
              </div>
            </div>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
}
