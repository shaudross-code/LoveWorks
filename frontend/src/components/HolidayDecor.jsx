import { useMemo } from "react";
import { useTheme } from "@/context/ThemeContext";

// Small greeting pill for the headers, e.g. "🎃 Happy Halloween"
export function HolidayBadge({ className = "" }) {
  const { state } = useTheme();
  const t = state?.theme;
  if (!t || state.effective === "default") return null;
  return (
    <span data-testid="holiday-badge" title={t.greeting}
      className={`inline-flex items-center gap-1.5 rounded-full border border-yellow-400/30 bg-yellow-400/10 text-yellow-300 px-2.5 h-7 text-xs font-semibold whitespace-nowrap ${className}`}>
      <span aria-hidden>{t.emoji}</span>
      <span className="hidden md:inline">{t.greeting}</span>
    </span>
  );
}

// Gentle drifting emoji decorations behind the UI (pointer-events: none)
export function HolidayFloaters() {
  const { state } = useTheme();
  const t = state?.theme;
  const items = useMemo(() => {
    if (!t) return [];
    return Array.from({ length: 9 }, (_, i) => ({
      id: i, emoji: t.emojis[i % t.emojis.length],
      left: `${(i * 11 + 4) % 96}%`, size: 16 + ((i * 7) % 14),
      duration: `${22 + (i * 5) % 16}s`, delay: `${-(i * 3.7) % 24}s`,
    }));
  }, [t]);
  if (!t || state.effective === "default") return null;
  return (
    <div aria-hidden data-testid="holiday-floaters">
      {items.map((f) => (
        <span key={f.id} className="holiday-floater"
          style={{ left: f.left, fontSize: f.size, animationDuration: f.duration, animationDelay: f.delay }}>
          {f.emoji}
        </span>
      ))}
    </div>
  );
}
