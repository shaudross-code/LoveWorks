import { Baby, Home, Package, Sandwich, Sparkles, User } from "lucide-react";

export const CATEGORIES = [
  { value: "household", label: "Household", icon: Home, color: "text-amber-400 bg-amber-400/10 border-amber-400/30" },
  { value: "everyday", label: "Everyday", icon: Sparkles, color: "text-yellow-400 bg-yellow-400/10 border-yellow-400/30" },
  { value: "groceries", label: "Groceries", icon: Sandwich, color: "text-emerald-400 bg-emerald-400/10 border-emerald-400/30" },
  { value: "personal", label: "Personal", icon: User, color: "text-sky-400 bg-sky-400/10 border-sky-400/30" },
  { value: "kids", label: "Kids", icon: Baby, color: "text-pink-400 bg-pink-400/10 border-pink-400/30" },
  { value: "other", label: "Other", icon: Package, color: "text-zinc-300 bg-zinc-700/40 border-zinc-600" },
];
export const catOf = (key) => CATEGORIES.find((c) => c.value === key) || CATEGORIES[CATEGORIES.length - 1];

export const lineTotal = (i) => Number(i.price || 0) * Number(i.quantity || 1);

// Category tab counts and money totals.
export function summarizeEssentials(items) {
  const counts = { all: items.length };
  CATEGORIES.forEach((c) => { counts[c.value] = 0; });
  const totals = { total: 0, purchased: 0, pending: 0, boughtCount: 0, openCount: 0 };
  items.forEach((i) => {
    const cat = i.category || "other";
    if (cat in counts) counts[cat] += 1;
    const v = lineTotal(i);
    totals.total += v;
    if (i.purchased) { totals.purchased += v; totals.boughtCount += 1; } else { totals.pending += v; totals.openCount += 1; }
  });
  totals.categories = CATEGORIES.filter((c) => counts[c.value] > 0).length;
  return { counts, totals };
}

export const emptyEssential = (assigneeId = "") => ({
  assignee_id: assigneeId, title: "", price: "", quantity: "1", category: "household", note: "", recurring: false, due_date: "",
});

export function essentialToForm(it) {
  return {
    assignee_id: it.owner_id,
    title: it.title || "",
    price: String(it.price ?? ""),
    quantity: String(it.quantity || 1),
    category: it.category || "other",
    note: it.note || "",
    recurring: !!it.recurring,
    due_date: it.due_date ? String(it.due_date).slice(0, 10) : "",
  };
}

export function validateEssential(form) {
  if (!form.title.trim()) return "Add a title";
  if (form.price === "" || Number.isNaN(parseFloat(form.price))) return "Enter a price";
  return null;
}

// Query string for POST /essentials.
export function essentialCreateParams(form) {
  const p = new URLSearchParams();
  p.set("title", form.title.trim());
  p.set("price", form.price);
  p.set("quantity", String(form.quantity || 1));
  p.set("category", form.category);
  if (form.note.trim()) p.set("note", form.note.trim());
  if (form.assignee_id) p.set("assignee_id", form.assignee_id);
  p.set("recurring", String(!!form.recurring));
  if (form.due_date) p.set("due_date", form.due_date);
  return p.toString();
}

export function essentialEditPayload(form) {
  return {
    title: form.title.trim() || undefined,
    price: form.price !== "" ? parseFloat(form.price) : undefined,
    quantity: form.quantity ? parseInt(form.quantity, 10) : undefined,
    category: form.category,
    note: form.note,
    recurring: !!form.recurring,
    due_date: form.due_date || null,
  };
}
