import { ArrowDown, ArrowUp, ArrowUpDown } from "lucide-react";

export function useSorted(rows, sort, valueOf) {
  const dir = sort.dir === "asc" ? 1 : -1;
  return [...rows].sort((a, b) => {
    const va = valueOf(a, sort.key);
    const vb = valueOf(b, sort.key);
    if (va == null && vb == null) return 0;
    if (va == null) return 1;
    if (vb == null) return -1;
    return (typeof va === "string" ? va.localeCompare(vb) : va - vb) * dir;
  });
}

export default function SortHeader({ label, k, sort, setSort, align = "right" }) {
  const active = sort.key === k;
  const Icon = !active ? ArrowUpDown : sort.dir === "asc" ? ArrowUp : ArrowDown;
  return (
    <th className={`px-4 py-3 font-medium whitespace-nowrap ${align === "right" ? "text-right" : "text-left"}`}>
      <button data-testid={`sort-${k}`} onClick={() => setSort({ key: k, dir: active && sort.dir === "desc" ? "asc" : "desc" })}
        className={`inline-flex items-center gap-1 uppercase tracking-widest text-[10px] transition-colors ${active ? "text-yellow-300" : "text-zinc-500 hover:text-zinc-300"}`}>
        {label} <Icon className="w-3 h-3" />
      </button>
    </th>
  );
}
