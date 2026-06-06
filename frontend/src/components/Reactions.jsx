import { useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import { Smile } from "lucide-react";
import { toast } from "sonner";

const EMOJIS = ["👍", "❤️", "🔥", "🎉", "⭐", "💪", "🙌", "💎"];

/**
 * <Reactions goal={...} onChange={(updated) => ...} />
 * Renders aggregated reactions + an emoji picker. Workers see counts only;
 * admins see counts + a picker to add/remove reactions.
 */
export default function Reactions({ goal, onChange }) {
  const { user } = useAuth();
  const [open, setOpen] = useState(false);
  const reactions = goal.reactions || [];

  // group counts + mine
  const groups = {};
  reactions.forEach((r) => {
    if (!groups[r.emoji]) groups[r.emoji] = { count: 0, mine: false };
    groups[r.emoji].count += 1;
    if (r.by_id === user?.id) groups[r.emoji].mine = true;
  });
  const entries = Object.entries(groups).sort((a, b) => b[1].count - a[1].count);

  const toggle = async (emoji) => {
    try {
      const { data } = await api.post(`/goals/${goal.id}/react`, { emoji });
      onChange?.(data);
      setOpen(false);
    } catch (e) { toast.error(formatApiError(e)); }
  };

  const canReact = user?.role === "admin";

  return (
    <div className="flex items-center gap-1.5 flex-wrap">
      {entries.map(([emoji, info]) => (
        <button
          key={emoji}
          type="button"
          data-testid={`goal-reaction-${goal.id}-${emoji}`}
          onClick={canReact ? () => toggle(emoji) : undefined}
          disabled={!canReact}
          className={`inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs border transition ${
            info.mine
              ? "bg-yellow-400/15 border-yellow-400/40 text-yellow-100"
              : "bg-zinc-900 border-zinc-800 text-zinc-300"
          } ${canReact ? "hover:bg-yellow-400/10 hover:border-yellow-400/40 cursor-pointer" : "cursor-default"}`}
          title={info.mine ? "Click to remove your reaction" : ""}
        >
          <span className="text-sm leading-none">{emoji}</span>
          <span className="font-display tabular-nums">{info.count}</span>
        </button>
      ))}

      {canReact && (
        <div className="relative">
          <button
            type="button"
            data-testid={`goal-reaction-picker-${goal.id}`}
            onClick={() => setOpen((v) => !v)}
            className="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs bg-zinc-900 border border-dashed border-yellow-400/30 text-yellow-300 hover:border-yellow-400/60 transition"
          >
            <Smile className="w-3 h-3" /> React
          </button>
          {open && (
            <div className="absolute z-30 mt-1 right-0 bg-[#0f0f12] border border-yellow-400/30 rounded-xl p-2 flex gap-1 shadow-2xl">
              {EMOJIS.map((e) => (
                <button
                  key={e}
                  type="button"
                  data-testid={`pick-emoji-${e}`}
                  onClick={() => toggle(e)}
                  className="w-9 h-9 grid place-items-center rounded-lg hover:bg-yellow-400/10 text-lg transition"
                >
                  {e}
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
