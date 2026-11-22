import { Flame, Scale, Bluetooth } from "lucide-react";
import { kgToLb, fmtKcal, timeAgo } from "@/lib/health";

// Admin Workers tab: the worker's latest calories and weight (only when they chose to share)
export default function WorkerHealthChip({ health, workerId }) {
  if (!health?.shared) {
    return <div data-testid={`worker-health-${workerId}`} className="mt-3 text-[11px] text-zinc-600">Health not shared</div>;
  }
  if (health.active_kcal == null && health.weight_kg == null) {
    return <div data-testid={`worker-health-${workerId}`} className="mt-3 text-[11px] text-zinc-500">Shared · no Apple Watch data yet</div>;
  }
  return (
    <div data-testid={`worker-health-${workerId}`} className="mt-3 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs">
      {health.active_kcal != null && (
        <span className="inline-flex items-center gap-1 text-pink-300">
          <Flame className="w-3.5 h-3.5" /> <b>{fmtKcal(health.active_kcal)}</b> active · {fmtKcal(health.total_kcal)} total kcal
        </span>
      )}
      {health.weight_kg != null && (
        <span className="inline-flex items-center gap-1 text-sky-300" title={health.weight_source === "scale_bluetooth" ? "Read from their scale over Bluetooth" : "From Apple Health"}>
          <Scale className="w-3.5 h-3.5" /> {kgToLb(health.weight_kg)} lb{health.weight_source === "scale_bluetooth" && <Bluetooth data-testid={`worker-weight-bt-${workerId}`} className="w-3 h-3 text-sky-400" />}
        </span>
      )}
      <span className="text-zinc-600">{health.date} · {timeAgo(health.updated_at)}</span>
    </div>
  );
}
