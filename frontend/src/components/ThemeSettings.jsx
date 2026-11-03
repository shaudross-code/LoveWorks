import { useState } from "react";
import { Palette, Loader2, CalendarDays } from "lucide-react";
import { toast } from "sonner";
import { useTheme } from "@/context/ThemeContext";
import { formatApiError } from "@/lib/api";

const fmt = (iso) => new Date(iso + "T12:00:00").toLocaleDateString(undefined, { month: "short", day: "numeric" });

export default function ThemeSettings() {
  const { state, setMode } = useTheme();
  const [busy, setBusy] = useState(null);
  if (!state) return null;

  const pick = async (mode) => {
    setBusy(mode);
    try {
      const d = await setMode(mode);
      const label = mode === "auto" ? `Auto — showing ${d.theme ? d.theme.name : "the default look"}` : mode === "default" ? "Default look restored" : `${d.theme.name} theme on`;
      toast.success(label);
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(null); }
  };

  const chip = (mode, label, emoji) => {
    const on = state.mode === mode;
    return (
      <button key={mode} type="button" data-testid={`theme-${mode}`} onClick={() => pick(mode)} disabled={!!busy}
        className={`min-h-10 px-3.5 rounded-full text-sm border transition inline-flex items-center gap-1.5 ${
          on ? "bg-yellow-400 text-black border-yellow-400 font-semibold" : "border-yellow-400/20 text-zinc-300 hover:border-yellow-400/50 hover:text-white"}`}>
        {busy === mode ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : emoji && <span aria-hidden>{emoji}</span>} {label}
      </button>
    );
  };

  const auto = state.themes.find((t) => t.key === state.auto_suggestion);
  return (
    <div className="mt-8 pt-6 border-t border-yellow-400/10" data-testid="theme-settings">
      <div className="text-xs uppercase tracking-widest text-zinc-500 inline-flex items-center gap-1.5"><Palette className="w-3.5 h-3.5" /> Holiday theme</div>
      <div className="mt-2 text-sm text-zinc-400 max-w-xl">
        The whole crew sees it. <span className="text-zinc-300">Auto</span> turns each holiday look on {state.window_days} days before and off {state.window_days} days after, then returns to the default gold look by itself.
      </div>
      <div className="mt-3 text-sm" data-testid="theme-status">
        Now showing: <span className="font-semibold text-yellow-300">{state.theme ? `${state.theme.emoji} ${state.theme.name}` : "Default look"}</span>
        {state.mode === "auto" && state.ends_on && <span className="text-zinc-500"> · back to default after {fmt(state.ends_on)}</span>}
        {state.mode === "auto" && !state.theme && auto == null && <span className="text-zinc-500"> · no holiday within {state.window_days} days</span>}
        {state.mode !== "auto" && <span className="text-zinc-500"> · set manually</span>}
      </div>
      <div className="mt-3 flex flex-wrap gap-2">
        {chip("auto", "Auto (recommended)", "✨")}
        {chip("default", "Default look", null)}
        {state.themes.map((t) => chip(t.key, t.name, t.emoji))}
      </div>
      {state.upcoming?.length > 0 && (
        <div className="mt-4 text-xs text-zinc-500" data-testid="theme-upcoming">
          <div className="inline-flex items-center gap-1.5 uppercase tracking-widest"><CalendarDays className="w-3.5 h-3.5" /> Auto schedule</div>
          <div className="mt-1.5 flex flex-wrap gap-x-4 gap-y-1">
            {state.upcoming.slice(0, 5).map((w) => (
              <span key={`${w.key}-${w.date}`}>{w.emoji} {w.name}: {fmt(w.starts)} – {fmt(w.ends)}</span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
