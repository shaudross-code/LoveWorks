import { useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Sparkles, PartyPopper } from "lucide-react";
import api from "@/lib/api";

/**
 * Big celebratory popup shown to a worker when one of their goals is freshly
 * completed by the admin (i.e. completed_at set and acknowledged_at null).
 */
export default function CongratsModal({ goal, onClose }) {
  // Acknowledge once when shown so it doesn't re-open
  useEffect(() => {
    if (!goal) return;
    api.post(`/goals/${goal.id}/acknowledge`).catch(() => {});
  }, [goal]);

  if (!goal) return null;
  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="bg-[#121214] border-yellow-400/30 text-white rounded-3xl max-w-md p-0 overflow-hidden" aria-describedby={undefined}>
        <div className="relative bg-gradient-to-br from-yellow-400 to-amber-500 text-black p-7 text-center">
          <div className="absolute inset-0 opacity-30 pointer-events-none"
            style={{ background: "radial-gradient(circle at 30% 20%, rgba(255,255,255,0.6), transparent 40%), radial-gradient(circle at 80% 60%, rgba(255,255,255,0.4), transparent 35%)" }} />
          <div className="relative">
            <PartyPopper className="w-12 h-12 mx-auto" />
            <DialogHeader className="mt-3">
              <DialogTitle className="font-display text-3xl font-bold tracking-tight">Goal achieved!</DialogTitle>
            </DialogHeader>
            <div className="mt-2 text-sm font-medium opacity-80">You earned it. Take the win.</div>
          </div>
        </div>
        <div className="p-6 space-y-4">
          <div className="text-center">
            <div className="text-xs uppercase tracking-widest text-yellow-400">Goal</div>
            <div className="font-display text-xl font-semibold mt-1">{goal.title}</div>
          </div>
          {goal.appreciation && (
            <div className="px-4 py-3 rounded-2xl bg-yellow-400/10 border border-yellow-400/30 text-sm text-yellow-100 flex items-start gap-2">
              <Sparkles className="w-4 h-4 text-yellow-400 mt-0.5 shrink-0" />
              <div><span className="text-yellow-400 font-semibold">From your admin:</span><br />{goal.appreciation}</div>
            </div>
          )}
          <Button data-testid="congrats-close" onClick={onClose}
            className="w-full h-11 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl">
            Thanks!
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
