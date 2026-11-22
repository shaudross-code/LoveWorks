const TONES = {
  yellow: { box: "from-yellow-400/[0.07] border-yellow-400/20", text: "text-yellow-400" },
  emerald: { box: "from-emerald-400/[0.07] border-emerald-400/25", text: "text-emerald-400" },
  rose: { box: "from-rose-400/[0.06] border-rose-400/20", text: "text-rose-300" },
};

// Money summary card used on Goals, Trips and Essentials.
export default function TotalCard({ testid, tone, icon: Icon, label, amount, sub }) {
  const t = TONES[tone];
  return (
    <div data-testid={testid}
      className={`relative overflow-hidden rounded-2xl p-5 bg-gradient-to-br via-[#121214] to-[#121214] border ${t.box}`}>
      <div className="text-xs uppercase tracking-widest text-zinc-500 flex items-center gap-1.5">
        <Icon className={`w-3.5 h-3.5 ${t.text}`} /> {label}
      </div>
      <div className={`mt-2 font-display text-3xl font-bold tabular-nums ${t.text}`}>${amount.toFixed(2)}</div>
      <div className="text-xs text-zinc-500 mt-1">{sub}</div>
    </div>
  );
}
