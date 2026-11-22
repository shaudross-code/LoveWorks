import { useMemo, useState } from "react";
import { CheckCircle2, Circle, Plus, ShoppingBag } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent } from "@/components/ui/dialog";
import ConfirmDeleteBody from "@/components/ConfirmDeleteBody";
import FilterTabs from "@/components/FilterTabs";
import OwnerFilter from "@/components/OwnerFilter";
import TotalCard from "@/components/TotalCard";
import EssentialCard from "@/components/essentials/EssentialCard";
import EssentialForm from "@/components/essentials/EssentialForm";
import { useAuth } from "@/context/AuthContext";
import { useDialogState } from "@/hooks/useDialogState";
import { useOwnedList, useOwnerScope } from "@/hooks/useOwnedList";
import api, { attempt } from "@/lib/api";
import { CATEGORIES, summarizeEssentials } from "@/lib/essentials";
import { plural } from "@/lib/format";

function Totals({ counts, totals }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <TotalCard testid="essentials-total" tone="yellow" icon={ShoppingBag} label="Grand total" amount={totals.total}
        sub={`${counts.all} item${plural(counts.all)} across ${totals.categories} categor${plural(totals.categories, "y", "ies")}`} />
      <TotalCard testid="essentials-pending" tone="rose" icon={Circle} label="Still to buy" amount={totals.pending} sub={`${totals.openCount} unchecked`} />
      <TotalCard testid="essentials-purchased" tone="emerald" icon={CheckCircle2} label="Stocked up" amount={totals.purchased} sub={`${totals.boughtCount} taken care of`} />
    </div>
  );
}

function EssentialDialog({ dialog, onClose, onDone, workers, reload }) {
  const remove = async () => {
    if (await attempt(() => api.delete(`/essentials/${dialog.item.id}`), "Removed")) onDone();
  };
  return (
    <Dialog open={dialog.open} onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
        {dialog.mode === "delete" ? (
          <ConfirmDeleteBody title="Remove from list?" confirmLabel="Remove" testSuffix="-essential" onConfirm={remove} onCancel={onClose}>
            <div>This removes <span className="font-semibold text-white">&ldquo;{dialog.item?.title}&rdquo;</span> from the essentials list. The photo will also be cleaned up.</div>
          </ConfirmDeleteBody>
        ) : dialog.mode && (
          <EssentialForm key={dialog.key} item={dialog.item} workers={workers} onDone={onDone} reload={reload} />
        )}
      </DialogContent>
    </Dialog>
  );
}

// Household essentials list (admin + worker).
export default function AdminEssentials() {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";
  const { items, workers, load } = useOwnedList("/essentials", isAdmin);
  const { owner, setOwner, scoped } = useOwnerScope(items, isAdmin);
  const [filter, setFilter] = useState("all");
  const dialog = useDialogState();
  const visible = useMemo(() => (filter === "all" ? scoped : scoped.filter((i) => (i.category || "other") === filter)), [scoped, filter]);
  const { counts, totals } = useMemo(() => summarizeEssentials(scoped), [scoped]);
  const tabs = [{ value: "all", label: "All", count: counts.all }, ...CATEGORIES.map((c) => ({ value: c.value, label: c.label, count: counts[c.value] }))];
  const done = () => { dialog.close(); load(); };
  const toggle = async (it) => { if (await attempt(() => api.patch(`/essentials/${it.id}`, { purchased: !it.purchased }))) load(); };

  return (
    <div className="space-y-8" data-testid="admin-essentials-page">
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Essentials</div>
          <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">The everyday list.</h1>
          <p className="mt-2 text-zinc-400">Household, groceries, kids' stuff — what the family needs, with a running total so nothing's a surprise.</p>
        </div>
        <Button data-testid="add-essential-btn" onClick={() => dialog.open("create")} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-10 px-5">
          <Plus className="w-4 h-4 mr-2" /> Add essential
        </Button>
      </div>
      {isAdmin && <OwnerFilter prefix="essentials" workers={workers} value={owner} onChange={setOwner} />}
      <Totals counts={counts} totals={totals} />
      <FilterTabs tabs={tabs} value={filter} onChange={setFilter} testPrefix="essential-tab-" />
      {visible.length === 0 ? (
        <div className="rounded-2xl border border-yellow-400/10 bg-[#121214] p-12 text-center text-zinc-400">
          Nothing here yet. Hit <span className="text-yellow-400 font-semibold">Add essential</span> to start the list.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {visible.map((it) => (
            <EssentialCard key={it.id} it={it} onToggle={() => toggle(it)} onEdit={() => dialog.open("edit", it)} onDelete={() => dialog.open("delete", it)} />
          ))}
        </div>
      )}
      <EssentialDialog dialog={dialog.state} onClose={dialog.close} onDone={done} workers={workers} reload={load} />
    </div>
  );
}
