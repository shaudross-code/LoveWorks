import { useMemo, useState } from "react";
import { CheckCircle2, Clock, Plus, Target } from "lucide-react";
import { Button } from "@/components/ui/button";
import FilterTabs from "@/components/FilterTabs";
import OwnerFilter from "@/components/OwnerFilter";
import TotalCard from "@/components/TotalCard";
import WishlistCard from "@/components/wishlist/WishlistCard";
import WishlistDialog from "@/components/wishlist/WishlistDialog";
import { useAuth } from "@/context/AuthContext";
import { useDialogState } from "@/hooks/useDialogState";
import { useOwnedList, useOwnerScope } from "@/hooks/useOwnedList";
import api, { attempt } from "@/lib/api";
import { STATUS_TABS, statusOf, summarize } from "@/lib/wishlist";
import { wishlistCopy } from "@/lib/wishlistCopy";

function Header({ copy, onAdd }) {
  return (
    <div className="flex items-start justify-between gap-4 flex-wrap">
      <div>
        <div className="text-xs uppercase tracking-widest text-yellow-400">{copy.kicker}</div>
        <h1 className="font-display text-3xl sm:text-4xl lg:text-5xl font-bold tracking-tight mt-2">{copy.heading}</h1>
        <p className="mt-2 text-zinc-400">{copy.blurb}</p>
      </div>
      <Button data-testid={copy.addTestid} onClick={onAdd} className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-10 px-5">
        <Plus className="w-4 h-4 mr-2" /> {copy.addLabel}
      </Button>
    </div>
  );
}

function Totals({ copy, counts, totals }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <TotalCard testid={`${copy.prefix}-total-all`} tone="yellow" icon={Target} label={copy.totalAll} amount={totals.all} sub={copy.totalAllSub(counts.all)} />
      <TotalCard testid={`${copy.prefix}-total-delivered`} tone="emerald" icon={CheckCircle2} label={copy.totalDone} amount={totals.completed} sub={copy.totalDoneSub(counts.completed)} />
      <TotalCard testid={`${copy.prefix}-total-outstanding`} tone="rose" icon={Clock} label={copy.totalLeft} amount={totals.outstanding} sub={copy.totalLeftSub(counts.all - counts.completed)} />
    </div>
  );
}

function Empty({ copy }) {
  const { pre, strong, post } = copy.empty;
  return (
    <div className="col-span-full bg-[#121214] border border-yellow-400/15 rounded-2xl p-10 text-center">
      <Target className="w-8 h-8 text-yellow-400 mx-auto" />
      <div className="mt-3 font-display text-xl">{copy.emptyTitle}</div>
      <div className="text-sm text-zinc-500">{pre}{strong && <span className="text-yellow-400 font-semibold">{strong}</span>}{post}</div>
    </div>
  );
}

// Shared Goals / Trips page (admin and worker).
export default function WishlistPage({ kind }) {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";
  const copy = wishlistCopy(kind, isAdmin);
  const { items: goals, setItems: setGoals, workers, load } = useOwnedList(`/goals?kind=${kind}`, isAdmin);
  const { owner, setOwner, scoped } = useOwnerScope(goals, isAdmin && copy.ownerFilter);
  const [filter, setFilter] = useState("all");
  const dialog = useDialogState();
  const visible = useMemo(() => (filter === "all" ? scoped : scoped.filter((g) => statusOf(g) === filter)), [scoped, filter]);
  const { counts, totals } = useMemo(() => summarize(scoped), [scoped]);
  const tabs = STATUS_TABS.map((s) => ({ value: s, label: s, count: counts[s] }));
  const done = () => { dialog.close(); load(); };
  const reopen = async (g) => { if (await attempt(() => api.post(`/goals/${g.id}/reopen`), copy.reopenedToast)) load(); };
  const react = (u) => setGoals((gs) => gs.map((x) => (x.id === u.id ? { ...x, reactions: u.reactions } : x)));

  return (
    <div className="space-y-8">
      <Header copy={copy} onAdd={() => dialog.open("assign")} />
      {copy.ownerFilter && <OwnerFilter prefix={copy.prefix} workers={workers} value={owner} onChange={setOwner} />}
      <Totals copy={copy} counts={counts} totals={totals} />
      <FilterTabs tabs={tabs} value={filter} onChange={setFilter} testPrefix={`${copy.prefix}-tab-`} />
      <div className="grid md:grid-cols-2 gap-4">
        {visible.length === 0 && <Empty copy={copy} />}
        {visible.map((g) => (
          <WishlistCard key={g.id} g={g} onReact={react} onReopen={() => reopen(g)}
            onEdit={() => dialog.open("edit", g)} onDelete={() => dialog.open("delete", g)} onCelebrate={() => dialog.open("complete", g)} />
        ))}
      </div>
      <WishlistDialog dialog={dialog.state} onClose={dialog.close} onDone={done} copy={copy} workers={workers} reload={load} />
    </div>
  );
}
