import { Calendar, ExternalLink, Pencil, RotateCcw, Sparkles, Target, Trash2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import Avatar from "@/components/Avatar";
import Reactions from "@/components/Reactions";
import GoalProgress, { GoalChips } from "@/components/wishlist/GoalProgress";
import { fileUrl } from "@/lib/api";
import { fmtDateLong, hostOf } from "@/lib/format";
import { isAhead, statusBadge, statusOf } from "@/lib/wishlist";

function OwnerLine({ g }) {
  const collabs = (g.collaborator_ids || []).length;
  return (
    <div className="mt-2 flex items-center gap-2 text-xs text-zinc-500">
      <Avatar url={g.owner?.avatar_url} name={g.owner?.name} size={20} />
      <span className="truncate">{g.owner?.name || g.owner?.email}</span>
      {collabs > 0 && (
        <span className="inline-flex items-center gap-1 px-2 h-5 rounded-full bg-pink-400/15 text-pink-300 border border-pink-400/30 text-[10px] uppercase tracking-widest"
          title={`Shared with ${collabs} teammate(s)`}>
          🤝 +{collabs}
        </span>
      )}
    </div>
  );
}

function CardActions({ g, onEdit, onDelete, onCelebrate, onReopen }) {
  return (
    <div className="mt-4 flex items-center gap-2 justify-end flex-wrap">
      <Button data-testid={`delete-goal-${g.id}`} onClick={onDelete} variant="ghost"
        className="text-zinc-400 hover:text-red-400 hover:bg-red-500/10 rounded-full h-9 px-3">
        <Trash2 className="w-4 h-4 mr-1.5" /> Delete
      </Button>
      <Button data-testid={`edit-goal-${g.id}`} onClick={onEdit} variant="ghost"
        className="text-zinc-300 hover:text-yellow-400 rounded-full h-9 px-4 border border-yellow-400/20">
        <Pencil className="w-4 h-4 mr-2" /> Edit goal
      </Button>
      {g.status === "open" ? (
        <Button data-testid={`celebrate-goal-${g.id}`} onClick={onCelebrate}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-9 px-4">
          <Sparkles className="w-4 h-4 mr-2" /> Celebrate
        </Button>
      ) : (
        <Button data-testid={`reopen-goal-${g.id}`} onClick={onReopen} variant="ghost"
          className="text-zinc-300 hover:text-yellow-400 rounded-full h-9 px-4 border border-yellow-400/20">
          <RotateCcw className="w-4 h-4 mr-2" /> Reopen
        </Button>
      )}
    </div>
  );
}

// Admin/worker card for one goal or trip.
export default function WishlistCard({ g, onReact, ...actions }) {
  const { Icon, cls, label } = statusBadge(statusOf(g));
  const done = g.status === "completed";
  return (
    <div data-testid={`admin-goal-${g.id}`}
      className={`bg-[#121214] border rounded-2xl p-4 sm:p-5 min-w-0 transition ${done ? "border-yellow-400/30 shadow-lg shadow-yellow-400/5" : "border-yellow-400/15"}`}>
      <div className="flex items-start gap-4 min-w-0">
        <div className="w-20 h-20 sm:w-24 sm:h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/10 grid place-items-center shrink-0">
          {g.image_url ? <img alt={g.title} src={fileUrl(g.image_url)} className="w-full h-full object-cover" />
            : <Target className="w-7 h-7 text-zinc-700" />}
        </div>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap">
            <div className={`font-display text-lg font-semibold break-words [overflow-wrap:anywhere] ${done ? "text-zinc-300" : "text-white"}`}>{g.title}</div>
            <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs ${cls}`}><Icon className="w-3 h-3" /> {label}</span>
            {isAhead(g) && (
              <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs bg-yellow-400/15 text-yellow-300">
                <Sparkles className="w-3 h-3" /> Ahead of deadline
              </span>
            )}
          </div>
          <OwnerLine g={g} />
          <div className="mt-2 flex flex-wrap items-center gap-2"><GoalChips g={g} /></div>
          <div className="mt-3 flex flex-wrap items-center gap-3 text-xs text-zinc-500">
            {g.deadline && <span className="inline-flex items-center gap-1"><Calendar className="w-3 h-3" /> by {fmtDateLong(g.deadline)}</span>}
            {g.product_link && (
              <a href={g.product_link} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-yellow-400 hover:underline truncate max-w-[220px]">
                <ExternalLink className="w-3 h-3" /> {hostOf(g.product_link)}
              </a>
            )}
          </div>
          <GoalProgress g={g} />
        </div>
      </div>
      {done && g.appreciation && (
        <div className="mt-4 px-3 py-2 rounded-xl bg-yellow-400/10 border border-yellow-400/30 text-sm text-yellow-100 flex items-start gap-2">
          <Sparkles className="w-4 h-4 text-yellow-400 mt-0.5 shrink-0" />
          <div>{g.appreciation}</div>
        </div>
      )}
      <div className="mt-3"><Reactions goal={g} onChange={onReact} /></div>
      <CardActions g={g} {...actions} />
    </div>
  );
}
