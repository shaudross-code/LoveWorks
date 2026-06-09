import { useMemo, useState } from "react";
import { Users, Plus, X } from "lucide-react";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { toast } from "sonner";
import api, { formatApiError } from "@/lib/api";
import Avatar from "@/components/Avatar";

/**
 * Collaborators editor for a doc (goal/trip/essential).
 *
 * Props:
 *   docId       — the goal_id / essential_id
 *   collection  — "goals" | "essentials"
 *   ownerId     — the owner's user id (excluded from the picker)
 *   collaboratorIds — current array of teammate user ids
 *   workers     — list of {id, name, email, avatar_url} for the picker (admin sees all)
 *   onChanged   — callback(newIds) when list changes
 *   label       — "Trip teammates", "Goal teammates", etc.
 */
export default function TeammatesField({ docId, collection, ownerId, collaboratorIds = [], workers = [], onChanged, label = "Teammates" }) {
  const [picked, setPicked] = useState("");
  const [busy, setBusy] = useState(false);

  const idToWorker = useMemo(() => {
    const m = {};
    workers.forEach((w) => { m[w.id] = w; });
    return m;
  }, [workers]);

  const eligible = useMemo(
    () => workers.filter((w) => w.id !== ownerId && !collaboratorIds.includes(w.id)),
    [workers, ownerId, collaboratorIds]
  );

  const add = async () => {
    if (!picked) return;
    setBusy(true);
    try {
      const { data } = await api.post(`/${collection}/${docId}/collaborators`, { user_id: picked });
      onChanged?.(data.collaborator_ids || [...collaboratorIds, picked]);
      setPicked("");
      toast.success("Teammate added 🤝");
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const remove = async (uid) => {
    setBusy(true);
    try {
      const { data } = await api.delete(`/${collection}/${docId}/collaborators/${uid}`);
      onChanged?.(data.collaborator_ids || collaboratorIds.filter((c) => c !== uid));
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  return (
    <div data-testid={`teammates-field-${collection}-${docId}`}>
      <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1">
        <Users className="w-3 h-3" /> {label}
      </label>
      <div className="mt-2 flex flex-wrap gap-2">
        {collaboratorIds.length === 0 && (
          <div className="text-xs text-zinc-500">No teammates yet — add someone to chip away at this together.</div>
        )}
        {collaboratorIds.map((id) => {
          const w = idToWorker[id];
          return (
            <span key={id} data-testid={`teammate-chip-${id}`}
              className="inline-flex items-center gap-1.5 pl-1.5 pr-2 h-7 rounded-full bg-pink-400/10 border border-pink-400/30 text-pink-200 text-xs">
              <Avatar url={w?.avatar_url} name={w?.name || w?.email || "?"} size={20} />
              <span className="truncate max-w-[140px]">{w?.name || w?.email || id.slice(0,8)}</span>
              <button data-testid={`teammate-remove-${id}`} disabled={busy} onClick={() => remove(id)}
                className="ml-0.5 w-4 h-4 rounded-full hover:bg-pink-400/20 grid place-items-center">
                <X className="w-3 h-3" />
              </button>
            </span>
          );
        })}
      </div>
      {eligible.length > 0 && (
        <div className="mt-3 flex items-center gap-2">
          <Select value={picked} onValueChange={setPicked}>
            <SelectTrigger data-testid={`teammate-picker-${collection}`} className="h-9 flex-1 bg-zinc-900 border-zinc-800 text-white rounded-xl text-sm">
              <SelectValue placeholder="Pick a teammate" />
            </SelectTrigger>
            <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
              {eligible.map((w) => (
                <SelectItem key={w.id} value={w.id} data-testid={`teammate-option-${w.id}`}>{w.name || w.email}</SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Button data-testid="teammate-add-btn" type="button" disabled={busy || !picked} onClick={add}
            className="h-9 bg-pink-500 hover:bg-pink-400 text-white rounded-full px-3 text-xs font-semibold">
            <Plus className="w-3.5 h-3.5 mr-1" /> Add
          </Button>
        </div>
      )}
    </div>
  );
}
