import { Dialog, DialogContent } from "@/components/ui/dialog";
import ConfirmDeleteBody from "@/components/ConfirmDeleteBody";
import AssignGoalForm from "@/components/wishlist/AssignGoalForm";
import CelebrateGoal from "@/components/wishlist/CelebrateGoal";
import EditGoalForm from "@/components/wishlist/EditGoalForm";
import api, { attempt } from "@/lib/api";

function DeleteGoal({ goal, copy, onDone, onCancel }) {
  const remove = async () => { if (await attempt(() => api.delete(`/goals/${goal.id}`), copy.deletedToast)) onDone(); };
  return (
    <ConfirmDeleteBody title={copy.deleteTitle} confirmLabel={copy.deleteLabel} onConfirm={remove} onCancel={onCancel}>
      <div>
        This permanently removes <span className="font-semibold text-white">&ldquo;{goal.title}&rdquo;</span> and all its reactions. Completed task earnings are <span className="font-semibold">not</span> affected — payroll still counts them.
      </div>
      <div className="text-xs text-zinc-500">This cannot be undone.</div>
    </ConfirmDeleteBody>
  );
}

const BODIES = { assign: AssignGoalForm, edit: EditGoalForm, delete: DeleteGoal, complete: CelebrateGoal };

// One dialog for assign / edit / delete / celebrate on the Goals & Trips pages.
export default function WishlistDialog({ dialog, onClose, onDone, copy, workers, reload }) {
  const Body = BODIES[dialog.mode];
  return (
    <Dialog open={dialog.open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
        {Body && <Body key={dialog.key} goal={dialog.item} copy={copy} workers={workers} reload={reload} onDone={onDone} onCancel={onClose} />}
      </DialogContent>
    </Dialog>
  );
}
