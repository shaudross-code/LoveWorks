import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

// "View by" worker filter for admin lists; testids use `${prefix}-owner-*`.
export default function OwnerFilter({ prefix, workers, value, onChange }) {
  if (!workers.length) return null;
  return (
    <div className="flex items-center gap-2 flex-wrap">
      <span className="text-xs uppercase tracking-widest text-zinc-500">View by</span>
      <Select value={value} onValueChange={onChange}>
        <SelectTrigger data-testid={`${prefix}-owner-filter`} className="h-9 w-56 bg-zinc-900 border-zinc-800 text-white rounded-full text-sm">
          <SelectValue />
        </SelectTrigger>
        <SelectContent className="bg-[#121214] border-yellow-400/20 text-white">
          <SelectItem value="all" data-testid={`${prefix}-owner-all`}>Every worker</SelectItem>
          {workers.map((w) => (
            <SelectItem key={w.id} value={w.id} data-testid={`${prefix}-owner-${w.id}`}>{w.name || w.email}</SelectItem>
          ))}
        </SelectContent>
      </Select>
      {value !== "all" && (
        <button onClick={() => onChange("all")} className="text-xs text-zinc-400 hover:text-yellow-400 px-2 h-9">Clear</button>
      )}
    </div>
  );
}
