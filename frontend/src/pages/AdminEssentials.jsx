import { useEffect, useMemo, useRef, useState } from "react";
import api, { formatApiError } from "@/lib/api";
import { useAuth } from "@/context/AuthContext";
import TeammatesField from "@/components/TeammatesField";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { toast } from "sonner";
import {
  Plus, ShoppingBag, Home, Sandwich, Sparkles, User, Baby, Package,
  Image as ImageIcon, Trash2, Pencil, Upload, Loader2, CheckCircle2, Circle, BadgeDollarSign, UserCircle2,
} from "lucide-react";

const CATEGORIES = [
  { value: "household", label: "Household",   icon: Home,      color: "text-amber-400 bg-amber-400/10 border-amber-400/30" },
  { value: "everyday",  label: "Everyday",    icon: Sparkles,  color: "text-yellow-400 bg-yellow-400/10 border-yellow-400/30" },
  { value: "groceries", label: "Groceries",   icon: Sandwich,  color: "text-emerald-400 bg-emerald-400/10 border-emerald-400/30" },
  { value: "personal",  label: "Personal",    icon: User,      color: "text-sky-400 bg-sky-400/10 border-sky-400/30" },
  { value: "kids",      label: "Kids",        icon: Baby,      color: "text-pink-400 bg-pink-400/10 border-pink-400/30" },
  { value: "other",     label: "Other",       icon: Package,   color: "text-zinc-300 bg-zinc-700/40 border-zinc-600" },
];
const catOf = (key) => CATEGORIES.find((c) => c.value === key) || CATEGORIES[CATEGORIES.length - 1];
const TABS = ["all", ...CATEGORIES.map((c) => c.value)];

export default function AdminEssentials() {
  const { user } = useAuth();
  const isAdmin = user?.role === "admin";
  const [items, setItems] = useState([]);
  const [workers, setWorkers] = useState([]);
  const [filter, setFilter] = useState("all");
  const [ownerFilter, setOwnerFilter] = useState("all");
  const [dialog, setDialog] = useState(null); // {mode:'create'|'edit'|'delete', item?}
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState({
    assignee_id: "", title: "", price: "", quantity: "1", category: "household", note: "", recurring: false, due_date: "",
  });
  const [uploadingImg, setUploadingImg] = useState(false);
  const fileRef = useRef(null);

  const load = async () => {
    const it = await api.get("/essentials");
    setItems(it.data);
    try {
      const w = await api.get(isAdmin ? "/workers" : "/peers");
      setWorkers(w.data);
    } catch { /* peers/workers list unavailable */ }
  };
  useEffect(() => { load(); }, []);

  const scopedItems = useMemo(() => {
    if (!isAdmin || ownerFilter === "all") return items;
    return items.filter((i) => i.owner_id === ownerFilter);
  }, [items, isAdmin, ownerFilter]);

  const visible = useMemo(() => filter === "all" ? scopedItems : scopedItems.filter((i) => (i.category || "other") === filter), [scopedItems, filter]);

  const counts = useMemo(() => {
    const c = { all: scopedItems.length };
    CATEGORIES.forEach((cat) => { c[cat.value] = scopedItems.filter((i) => (i.category || "other") === cat.value).length; });
    return c;
  }, [scopedItems]);

  const totals = useMemo(() => {
    const line = (i) => Number(i.price || 0) * Number(i.quantity || 1);
    let total = 0, purchased = 0, pending = 0;
    scopedItems.forEach((i) => {
      const v = line(i);
      total += v;
      if (i.purchased) purchased += v; else pending += v;
    });
    return { total, purchased, pending };
  }, [scopedItems]);

  const openCreate = () => {
    setForm({ assignee_id: workers[0]?.id || "", title: "", price: "", quantity: "1", category: "household", note: "", recurring: false, due_date: "" });
    setDialog({ mode: "create" });
  };
  const openEdit = (it) => {
    setForm({
      assignee_id: it.owner_id, title: it.title || "",
      price: String(it.price ?? ""), quantity: String(it.quantity || 1),
      category: it.category || "other", note: it.note || "",
      recurring: !!it.recurring,
      due_date: it.due_date ? String(it.due_date).slice(0, 10) : "",
    });
    setDialog({ mode: "edit", item: it });
  };
  const openDelete = (it) => setDialog({ mode: "delete", item: it });

  const submitCreate = async () => {
    if (!form.title.trim()) { toast.error("Add a title"); return; }
    if (form.price === "" || isNaN(parseFloat(form.price))) { toast.error("Enter a price"); return; }
    setBusy(true);
    try {
      const params = new URLSearchParams();
      params.set("title", form.title.trim());
      params.set("price", form.price);
      params.set("quantity", String(form.quantity || 1));
      params.set("category", form.category);
      if (form.note.trim()) params.set("note", form.note.trim());
      if (form.assignee_id) params.set("assignee_id", form.assignee_id);
      params.set("recurring", String(!!form.recurring));
      if (form.due_date) params.set("due_date", form.due_date);
      await api.post(`/essentials?${params.toString()}`, new FormData(), { headers: { "Content-Type": "multipart/form-data" } });
      toast.success("Essential added 🛒");
      setDialog(null); load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const submitEdit = async () => {
    if (!dialog?.item) return;
    setBusy(true);
    try {
      await api.patch(`/essentials/${dialog.item.id}`, {
        title: form.title.trim() || undefined,
        price: form.price !== "" ? parseFloat(form.price) : undefined,
        quantity: form.quantity ? parseInt(form.quantity, 10) : undefined,
        category: form.category,
        note: form.note,
        recurring: !!form.recurring,
        due_date: form.due_date || null,
      });
      toast.success("Essential updated");
      setDialog(null); load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const submitDelete = async () => {
    if (!dialog?.item) return;
    setBusy(true);
    try {
      await api.delete(`/essentials/${dialog.item.id}`);
      toast.success("Removed");
      setDialog(null); load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const togglePurchased = async (it) => {
    try {
      await api.patch(`/essentials/${it.id}`, { purchased: !it.purchased });
      load();
    } catch (e) { toast.error(formatApiError(e)); }
  };

  const onPickImage = () => fileRef.current?.click();
  const uploadImage = async (file) => {
    if (!dialog?.item || !file) return;
    if (file.size > 3 * 1024 * 1024) { toast.error("Image too large (max 3 MB)"); return; }
    setUploadingImg(true);
    try {
      const fd = new FormData(); fd.append("file", file);
      const { data } = await api.post(`/essentials/${dialog.item.id}/image`, fd, { headers: { "Content-Type": "multipart/form-data" } });
      setDialog((d) => d?.item ? { ...d, item: { ...d.item, image_url: data.image_url, image_path: data.image_path } } : d);
      toast.success("Photo saved");
      load();
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setUploadingImg(false); if (fileRef.current) fileRef.current.value = ""; }
  };

  return (
    <div className="space-y-8" data-testid="admin-essentials-page">
      {/* Header */}
      <div className="flex items-start justify-between gap-4 flex-wrap">
        <div>
          <div className="text-xs uppercase tracking-widest text-yellow-400">Essentials</div>
          <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">The everyday list.</h1>
          <p className="mt-2 text-zinc-400">Household, groceries, kids' stuff — what the family needs, with a running total so nothing's a surprise.</p>
        </div>
        <Button data-testid="add-essential-btn" onClick={openCreate}
          className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-full h-10 px-5">
          <Plus className="w-4 h-4 mr-2" /> Add essential
        </Button>
      </div>

      {isAdmin && workers.length > 0 && (
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-xs uppercase tracking-widest text-zinc-500">View by</span>
          <Select value={ownerFilter} onValueChange={setOwnerFilter}>
            <SelectTrigger data-testid="essentials-owner-filter" className="h-9 w-56 bg-zinc-900 border-zinc-800 text-white rounded-full text-sm">
              <SelectValue />
            </SelectTrigger>
            <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
              <SelectItem value="all" data-testid="essentials-owner-all">Every worker</SelectItem>
              {workers.map((w) => (
                <SelectItem key={w.id} value={w.id} data-testid={`essentials-owner-${w.id}`}>
                  {w.name || w.email}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          {ownerFilter !== "all" && (
            <button onClick={() => setOwnerFilter("all")}
              className="text-xs text-zinc-400 hover:text-yellow-400 px-2 h-9">
              Clear
            </button>
          )}
        </div>
      )}

      {/* Totals strip */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div data-testid="essentials-total"
          className="relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br from-yellow-400/[0.07] via-[#121214] to-[#121214] border border-yellow-400/20">
          <div className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
            <ShoppingBag className="w-3.5 h-3.5 text-yellow-400" /> Grand total
          </div>
          <div className="mt-2 font-display text-3xl font-bold text-yellow-400 tabular-nums">${totals.total.toFixed(2)}</div>
          <div className="text-xs text-zinc-500 mt-1">{items.length} item{items.length === 1 ? "" : "s"} across {CATEGORIES.filter(c => counts[c.value] > 0).length} categor{CATEGORIES.filter(c => counts[c.value] > 0).length === 1 ? "y" : "ies"}</div>
        </div>
        <div data-testid="essentials-pending"
          className="relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br from-rose-400/[0.06] via-[#121214] to-[#121214] border border-rose-400/20">
          <div className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
            <Circle className="w-3.5 h-3.5 text-rose-300" /> Still to buy
          </div>
          <div className="mt-2 font-display text-3xl font-bold text-rose-300 tabular-nums">${totals.pending.toFixed(2)}</div>
          <div className="text-xs text-zinc-500 mt-1">{items.filter((i) => !i.purchased).length} unchecked</div>
        </div>
        <div data-testid="essentials-purchased"
          className="relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br from-emerald-400/[0.07] via-[#121214] to-[#121214] border border-emerald-400/25">
          <div className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
            <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" /> Stocked up
          </div>
          <div className="mt-2 font-display text-3xl font-bold text-emerald-400 tabular-nums">${totals.purchased.toFixed(2)}</div>
          <div className="text-xs text-zinc-500 mt-1">{items.filter((i) => i.purchased).length} taken care of</div>
        </div>
      </div>

      {/* Category tabs */}
      <Tabs value={filter} onValueChange={setFilter}>
        <TabsList className="bg-[#121214] border border-yellow-400/15 rounded-xl p-1 flex flex-wrap h-auto">
          {TABS.map((t) => {
            const isAll = t === "all";
            const cat = isAll ? null : catOf(t);
            return (
              <TabsTrigger key={t} value={t} data-testid={`essential-tab-${t}`}
                className="rounded-lg data-[state=active]:bg-yellow-400 data-[state=active]:text-black capitalize">
                {isAll ? "All" : cat.label}
                <span className="ml-1.5 text-xs opacity-60">{counts[t] || 0}</span>
              </TabsTrigger>
            );
          })}
        </TabsList>
      </Tabs>

      {/* Grid */}
      {visible.length === 0 ? (
        <div className="rounded-2xl border border-yellow-400/10 bg-[#121214] p-12 text-center text-zinc-400">
          Nothing here yet. Hit <span className="text-yellow-400 font-semibold">Add essential</span> to start the list.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {visible.map((it) => {
            const cat = catOf(it.category);
            const line = Number(it.price || 0) * Number(it.quantity || 1);
            return (
              <div key={it.id} data-testid={`essential-${it.id}`}
                className={`rounded-2xl border bg-[#121214] p-4 flex gap-4 ${it.purchased ? "border-emerald-400/30 opacity-70" : "border-yellow-400/10 hover:border-yellow-400/30"} transition`}>
                <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/10 grid place-items-center shrink-0">
                  {it.image_url ? (
                    <img src={it.image_url} alt={`Photo of ${it.title}`} className="w-full h-full object-cover" />
                  ) : (
                    <cat.icon className="w-8 h-8 text-zinc-700" />
                  )}
                </div>
                <div className="flex-1 min-w-0 flex flex-col">
                  <div className="flex items-start gap-2 flex-wrap">
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest border ${cat.color}`}>
                      <cat.icon className="w-3 h-3" /> {cat.label}
                    </span>
                    {it.owner && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] uppercase tracking-widest bg-zinc-800 text-zinc-400">
                        <UserCircle2 className="w-3 h-3" /> {it.owner.name || it.owner.email}
                      </span>
                    )}
                  </div>
                  <div className={`mt-1 font-display font-semibold text-lg leading-tight ${it.purchased ? "line-through text-zinc-500" : ""}`}>
                    {it.title}
                  </div>
                  {it.note && <div className="text-xs text-zinc-500 mt-0.5">{it.note}</div>}
                  <div className="mt-1.5 flex flex-wrap gap-1.5 text-[10px] uppercase tracking-widest">
                    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full border ${
                      it.recurring
                        ? "bg-emerald-400/10 text-emerald-300 border-emerald-400/30"
                        : "bg-pink-400/10 text-pink-300 border-pink-400/30"
                    }`}>
                      {it.recurring ? "🔁 recurring" : "✨ one-time"}
                    </span>
                    {it.due_date && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-amber-400/10 text-amber-300 border border-amber-400/30">
                        📅 due {new Date(it.due_date).toLocaleDateString(undefined, { month: "short", day: "numeric" })}
                      </span>
                    )}
                    {it.completed_at && (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-300 border border-emerald-400/30">
                        ✓ {new Date(it.completed_at).toLocaleDateString(undefined, { month: "short", day: "numeric" })}
                      </span>
                    )}
                  </div>
                  <div className="mt-auto pt-3 flex items-end justify-between gap-3 flex-wrap">
                    <div className="flex items-baseline gap-2 tabular-nums">
                      <span className={`font-display font-bold text-2xl ${it.purchased ? "text-zinc-400" : "text-yellow-400"}`}>
                        ${line.toFixed(2)}
                      </span>
                      <span className="text-xs text-zinc-500">
                        ${Number(it.price || 0).toFixed(2)} × {it.quantity || 1}
                      </span>
                    </div>
                    <div className="flex items-center gap-1.5">
                      <button data-testid={`toggle-purchased-${it.id}`} onClick={() => togglePurchased(it)}
                        title={it.purchased ? "Mark as needed again" : "Mark as bought"}
                        className={`w-8 h-8 rounded-full grid place-items-center transition ${it.purchased
                          ? "bg-emerald-400/15 text-emerald-400 hover:bg-emerald-400/25"
                          : "bg-zinc-800 text-zinc-400 hover:bg-zinc-700 hover:text-emerald-400"}`}>
                        <CheckCircle2 className="w-4 h-4" />
                      </button>
                      <button data-testid={`edit-essential-${it.id}`} onClick={() => openEdit(it)}
                        className="w-8 h-8 rounded-full bg-zinc-800 text-zinc-400 hover:text-yellow-400 grid place-items-center transition">
                        <Pencil className="w-4 h-4" />
                      </button>
                      <button data-testid={`delete-essential-${it.id}`} onClick={() => openDelete(it)}
                        className="w-8 h-8 rounded-full bg-zinc-800 text-zinc-400 hover:text-red-400 hover:bg-red-500/10 grid place-items-center transition">
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Dialog */}
      <Dialog open={!!dialog} onOpenChange={(o) => !o && setDialog(null)}>
        <DialogContent className="bg-[#121214] border-yellow-400/20 text-white rounded-2xl" aria-describedby={undefined}>
          {dialog?.mode === "delete" ? (
            <>
              <DialogHeader>
                <DialogTitle className="font-display text-2xl flex items-center gap-2">
                  <Trash2 className="w-5 h-5 text-red-400" /> Remove from list?
                </DialogTitle>
              </DialogHeader>
              <div className="text-sm text-zinc-300">
                This removes <span className="font-semibold text-white">&ldquo;{dialog?.item?.title}&rdquo;</span> from the essentials list. The photo will also be cleaned up.
              </div>
              <DialogFooter className="flex gap-2">
                <Button data-testid="cancel-delete-essential" variant="ghost" onClick={() => setDialog(null)}
                  className="text-zinc-300 hover:text-white rounded-xl h-11 px-4 border border-zinc-700">Cancel</Button>
                <Button data-testid="confirm-delete-essential" onClick={submitDelete} disabled={busy}
                  className="bg-red-500 hover:bg-red-400 text-white font-semibold rounded-xl h-11 flex-1">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Trash2 className="w-4 h-4 mr-2" /> Remove</>}
                </Button>
              </DialogFooter>
            </>
          ) : (
            <>
              <DialogHeader>
                <DialogTitle className="font-display text-2xl flex items-center gap-2">
                  <ShoppingBag className="w-5 h-5 text-yellow-400" />
                  {dialog?.mode === "edit" ? "Edit essential" : "Add essential"}
                </DialogTitle>
              </DialogHeader>
              <div className="space-y-4">
                {/* Image (edit-mode only) */}
                {dialog?.mode === "edit" && (
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><ImageIcon className="w-3 h-3" /> Photo</label>
                    <div className="mt-2 flex items-center gap-4">
                      <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/20 shrink-0 grid place-items-center">
                        {dialog?.item?.image_url ? (
                          <img src={dialog.item.image_url} alt={`Photo of ${dialog.item.title}`} className="w-full h-full object-cover" />
                        ) : (
                          <ImageIcon className="w-7 h-7 text-zinc-700" />
                        )}
                      </div>
                      <div>
                        <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp,image/gif"
                          className="hidden" onChange={(e) => uploadImage(e.target.files?.[0])} data-testid="essential-image-input" />
                        <Button data-testid="essential-image-upload-btn" type="button" onClick={onPickImage} disabled={uploadingImg}
                          className="bg-yellow-400 hover:bg-yellow-300 text-black rounded-full h-9 px-4 text-sm font-semibold">
                          {uploadingImg ? <Loader2 className="w-4 h-4 animate-spin mr-1.5" /> : <Upload className="w-4 h-4 mr-1.5" />}
                          {dialog?.item?.image_url ? "Replace" : "Upload photo"}
                        </Button>
                        <div className="text-[10px] text-zinc-500 mt-2">JPEG/PNG/WEBP/GIF — up to 3 MB</div>
                      </div>
                    </div>
                  </div>
                )}

                {dialog?.mode === "edit" && dialog?.item && (
                  <TeammatesField
                    docId={dialog.item.id}
                    collection="essentials"
                    ownerId={dialog.item.owner_id}
                    collaboratorIds={dialog.item.collaborator_ids || []}
                    workers={workers}
                    label="Essential teammates"
                    onChanged={(ids) => {
                      setDialog((d) => d?.item ? { ...d, item: { ...d.item, collaborator_ids: ids } } : d);
                      load();
                    }}
                  />
                )}

                {dialog?.mode === "create" && workers.length > 0 && (
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><UserCircle2 className="w-3 h-3" /> For (optional)</label>
                    <Select value={form.assignee_id || "self"} onValueChange={(v) => setForm({ ...form, assignee_id: v === "self" ? "" : v })}>
                      <SelectTrigger data-testid="essential-assignee" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11"><SelectValue /></SelectTrigger>
                      <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                        <SelectItem value="self">Keep on my list</SelectItem>
                        {workers.map((w) => <SelectItem key={w.id} value={w.id}>{w.name || w.email}</SelectItem>)}
                      </SelectContent>
                    </Select>
                  </div>
                )}

                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Title</label>
                  <Input data-testid="essential-title" value={form.title}
                    onChange={(e) => setForm({ ...form, title: e.target.value })}
                    placeholder="e.g., Dish soap, Diapers, Bread"
                    className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1"><BadgeDollarSign className="w-3 h-3" /> Price</label>
                    <Input data-testid="essential-price" type="number" min="0" step="0.01" placeholder="e.g., 8.99"
                      value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })}
                      className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  </div>
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500">Quantity</label>
                    <Input data-testid="essential-quantity" type="number" min="1" step="1"
                      value={form.quantity} onChange={(e) => setForm({ ...form, quantity: e.target.value })}
                      className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  </div>
                </div>

                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Category</label>
                  <Select value={form.category} onValueChange={(v) => setForm({ ...form, category: v })}>
                    <SelectTrigger data-testid="essential-category" className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11"><SelectValue /></SelectTrigger>
                    <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
                      {CATEGORIES.map((c) => <SelectItem key={c.value} value={c.value} data-testid={`essential-category-${c.value}`}>{c.label}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <label className="text-xs uppercase tracking-widest text-zinc-500">Note (optional)</label>
                  <Input data-testid="essential-note" value={form.note}
                    onChange={(e) => setForm({ ...form, note: e.target.value })}
                    placeholder="e.g., the lavender scent"
                    className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500">Type</label>
                    <button data-testid="essential-recurring-toggle" type="button"
                      onClick={() => setForm({ ...form, recurring: !form.recurring })}
                      className={`mt-2 w-full h-11 rounded-xl text-sm font-semibold transition border ${
                        form.recurring
                          ? "bg-emerald-400/15 text-emerald-300 border-emerald-400/40"
                          : "bg-pink-400/10 text-pink-300 border-pink-400/40"
                      }`}>
                      {form.recurring ? "🔁 Recurring" : "✨ One-time"}
                    </button>
                  </div>
                  <div>
                    <label className="text-xs uppercase tracking-widest text-zinc-500">Due date (optional)</label>
                    <Input data-testid="essential-due-date" type="date" value={form.due_date}
                      onChange={(e) => setForm({ ...form, due_date: e.target.value })}
                      className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-11" />
                  </div>
                </div>
              </div>
              <DialogFooter>
                <Button data-testid="confirm-essential" onClick={dialog?.mode === "edit" ? submitEdit : submitCreate} disabled={busy}
                  className="bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl h-11 w-full">
                  {busy ? <Loader2 className="w-4 h-4 animate-spin" /> :
                    (dialog?.mode === "edit" ? "Save changes" : <><Plus className="w-4 h-4 mr-2" /> Add to list</>)}
                </Button>
              </DialogFooter>
            </>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
