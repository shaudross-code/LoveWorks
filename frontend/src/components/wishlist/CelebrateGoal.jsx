import { useState } from "react";
import { Loader2, Sparkles } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import api, { attempt } from "@/lib/api";
import { QUICK_QUOTES, celebrateText } from "@/lib/wishlist";

// Admin marks a goal/trip complete with a note the worker sees in a congrats popup.
export default function CelebrateGoal({ goal, copy, onDone }) {
  const [appreciation, setAppreciation] = useState(() => celebrateText(goal));
  const [busy, setBusy] = useState(false);
  const submit = async () => {
    setBusy(true);
    const ok = await attempt(() => api.post(`/goals/${goal.id}/complete`, { appreciation }), copy.celebratedToast);
    setBusy(false);
    if (ok) onDone();
  };
  return (
    <>
      <DialogHeader>
        <DialogTitle className="font-display text-2xl flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-yellow-400" /> Celebrate this goal
        </DialogTitle>
      </DialogHeader>
      <div className="space-y-3">
        <div className="text-sm text-zinc-400">Pick a quick note or write your own — the worker will see it in a big congrats popup.</div>
        <div className="flex flex-wrap gap-2">
          {QUICK_QUOTES.map((q) => (
            <button key={q} type="button" data-testid={`quote-${q.replace(/[^a-z]/gi, "").slice(0, 12)}`} onClick={() => setAppreciation(q)}
              className="text-xs px-3 py-1.5 rounded-full bg-zinc-900 border border-yellow-400/20 hover:border-yellow-400/60 hover:bg-yellow-400/10 transition">
              {q}
            </button>
          ))}
        </div>
        <Textarea data-testid="appreciation-textarea" value={appreciation} onChange={(e) => setAppreciation(e.target.value)}
          placeholder="You earned this. Proud of the hustle." className="bg-zinc-900 border-zinc-800 text-white rounded-xl min-h-24" />
      </div>
      <DialogFooter>
        <Button data-testid="confirm-celebrate" onClick={submit} disabled={busy}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Mark complete & send appreciation"}
        </Button>
      </DialogFooter>
    </>
  );
}
