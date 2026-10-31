import { Clock, AlertTriangle } from "lucide-react";
import { isStale } from "@/lib/sizes";

export default function LastUpdated({ doc, selfId }) {
  if (!doc?.updated_at || !Object.keys(doc.values || {}).length) {
    return <div className="text-sm text-zinc-500 inline-flex items-center gap-1.5" data-testid="last-updated"><Clock className="w-3.5 h-3.5" /> No sizes recorded yet</div>;
  }
  const by = doc.updated_by;
  const who = !by ? "" : by.id === selfId ? "you" : `${by.name}${by.role === "admin" ? " (admin)" : ""}`;
  const date = new Date(doc.updated_at).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
  return (
    <div className="flex flex-wrap items-center gap-2" data-testid="last-updated">
      <span className="text-sm text-zinc-400 inline-flex items-center gap-1.5"><Clock className="w-3.5 h-3.5" /> Last updated {date}{who && ` by ${who}`}</span>
      {isStale(doc.updated_at) && (
        <span data-testid="stale-badge" className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-amber-400/15 text-amber-300 border border-amber-400/30">
          <AlertTriangle className="w-3 h-3" /> over a year old — still accurate?
        </span>
      )}
    </div>
  );
}
