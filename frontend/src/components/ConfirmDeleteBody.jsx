import { useState } from "react";
import { Loader2, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

// Body of a "Delete X?" dialog. testSuffix keeps existing ids (e.g. "-essential" → confirm-delete-essential).
export default function ConfirmDeleteBody({ title, children, confirmLabel, testSuffix = "", onConfirm, onCancel }) {
  const [busy, setBusy] = useState(false);
  const confirm = async () => {
    setBusy(true);
    try { await onConfirm(); } finally { setBusy(false); }
  };
  return (
    <>
      <DialogHeader>
        <DialogTitle className="font-display text-2xl flex items-center gap-2">
          <Trash2 className="w-5 h-5 text-red-400" /> {title}
        </DialogTitle>
      </DialogHeader>
      <div className="space-y-3 text-sm text-zinc-300">{children}</div>
      <DialogFooter className="flex gap-2 sm:gap-2">
        <Button data-testid={`cancel-delete${testSuffix}`} type="button" variant="ghost" onClick={onCancel}
          className="text-zinc-300 hover:text-white rounded-xl h-11 px-4 border border-zinc-700">
          Cancel
        </Button>
        <Button data-testid={`confirm-delete${testSuffix}`} onClick={confirm} disabled={busy}
          className="bg-red-500 hover:bg-red-400 text-white font-semibold rounded-xl h-11 flex-1">
          {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Trash2 className="w-4 h-4 mr-2" /> {confirmLabel}</>}
        </Button>
      </DialogFooter>
    </>
  );
}
