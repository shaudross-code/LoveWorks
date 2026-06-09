import { useEffect, useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Eye, EyeOff, Loader2, ShieldCheck, Heart, Gift, Plane, Flower2, Wine, Gem, Banknote, KeyRound, ShoppingBag, Shirt } from "lucide-react";

// Romantic gift backdrop — each icon floats independently around the brand panel
const BACKDROP_ICONS = [
  { Icon: Heart,      top: "8%",  left: "6%",   delay: "0s",   size: 44, tint: "text-pink-400/30",    spin: 12 },
  { Icon: Gift,       top: "20%", left: "78%",  delay: "0.6s", size: 38, tint: "text-rose-400/30",    spin: -8 },
  { Icon: Plane,      top: "62%", left: "9%",   delay: "1.2s", size: 40, tint: "text-fuchsia-400/25", spin: 18 },
  { Icon: Flower2,    top: "78%", left: "70%",  delay: "0.3s", size: 46, tint: "text-pink-300/30",    spin: -14 },
  { Icon: Wine,       top: "44%", left: "82%",  delay: "1.5s", size: 36, tint: "text-rose-300/25",    spin: 6 },
  { Icon: Gem,        top: "30%", left: "30%",  delay: "0.9s", size: 30, tint: "text-yellow-400/25",  spin: 22 },
  { Icon: Banknote,   top: "84%", left: "30%",  delay: "0.4s", size: 38, tint: "text-emerald-300/25", spin: -10 },
  { Icon: KeyRound,   top: "12%", left: "48%",  delay: "1.8s", size: 32, tint: "text-yellow-300/30",  spin: 16 },
  { Icon: ShoppingBag,top: "56%", left: "55%",  delay: "1.1s", size: 34, tint: "text-pink-400/25",    spin: -18 },
  { Icon: Shirt,      top: "70%", left: "40%",  delay: "0.2s", size: 32, tint: "text-fuchsia-300/25", spin: 10 },
];

export default function Login() {
  const { user, login } = useAuth();
  const nav = useNavigate();
  const loc = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [show, setShow] = useState(false);
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (user && typeof user === "object") {
      nav(user.role === "admin" ? "/admin" : "/worker", { replace: true });
    }
  }, [user, nav]);

  const onSubmit = async (e) => {
    e.preventDefault();
    setError("");
    setBusy(true);
    const res = await login(email.trim(), password);
    setBusy(false);
    if (!res.ok) { setError(res.error); return; }
    const dest = res.user.role === "admin" ? "/admin" : "/worker";
    nav(loc.state?.from?.pathname || dest, { replace: true });
  };

  return (
    <div className="min-h-screen bg-[#09090B] text-white relative overflow-hidden flex">
      {/* Decorative gradients */}
      <div className="absolute -top-40 -left-40 w-[520px] h-[520px] bg-pink-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-0 right-0 w-[460px] h-[460px] bg-yellow-500/5 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute top-1/3 left-1/2 w-[360px] h-[360px] bg-rose-500/[0.06] rounded-full blur-3xl pointer-events-none" />

      {/* Floating love-gift backdrop */}
      <div aria-hidden="true" className="absolute inset-0 pointer-events-none overflow-hidden hidden md:block">
        {BACKDROP_ICONS.map(({ Icon, top, left, delay, size, tint, spin }, i) => (
          <Icon
            key={i}
            className={`absolute ${tint} love-float`}
            style={{
              top, left, width: size, height: size,
              animationDelay: delay,
              transform: `rotate(${spin}deg)`,
            }}
          />
        ))}
      </div>

      {/* Left: brand */}
      <div className="hidden lg:flex flex-1 flex-col justify-between p-12 border-r border-pink-400/10 relative">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-pink-400 to-rose-500 text-white grid place-items-center shadow-lg shadow-pink-500/30">
            <Heart className="w-6 h-6 fill-white" />
          </div>
          <div>
            <div className="font-display text-2xl font-bold leading-none">LoveWorks</div>
            <div className="text-xs text-zinc-500 mt-1 uppercase tracking-widest">Love · Tasks · Gifts</div>
          </div>
        </div>
        <div className="relative">
          <h1 className="font-display text-5xl xl:text-6xl font-bold tracking-tight leading-[1.05]">
            <span className="text-pink-400 drop-shadow-[0_0_22px_rgba(244,114,182,0.35)]">Show your Love.</span> <br />
            <span className="text-yellow-400">Get Loved with Gifts.</span>
          </h1>
          <p className="mt-6 max-w-md text-zinc-400 text-base leading-relaxed">
            Track everyday acts of love — work, study, breaks, parenting — set goals,
            and let appreciation flow back as gifts. Charmingly pink &amp; gold.
          </p>
          <div className="mt-10 flex items-center gap-3 text-zinc-500 text-sm">
            <ShieldCheck className="w-4 h-4 text-pink-400" />
            Secured with JWT · Admin invitations only
          </div>
        </div>
        <div className="text-xs text-zinc-600">© LoveWorks — built with love &amp; gold.</div>
      </div>

      {/* Right: form */}
      <div className="flex-1 flex items-center justify-center p-6 sm:p-12 relative">
        <form onSubmit={onSubmit} className="w-full max-w-md bg-[#121214] border border-pink-400/15 rounded-2xl p-8 shadow-2xl shadow-pink-500/10 fade-up relative z-10">
          <div className="lg:hidden flex items-center gap-2 mb-6">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-pink-400 to-rose-500 grid place-items-center shadow-md shadow-pink-500/30">
              <Heart className="w-5 h-5 text-white fill-white" />
            </div>
            <div className="font-display font-bold text-lg">LoveWorks</div>
          </div>
          <h2 className="font-display text-3xl font-bold tracking-tight">Welcome back</h2>
          <p className="mt-1 text-sm text-zinc-500">Sign in to manage your workday.</p>

          <div className="mt-7 space-y-4">
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500">Email</label>
              <Input
                data-testid="login-email"
                type="email"
                value={email}
                required
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@company.com"
                className="mt-2 bg-zinc-900/70 border-zinc-800 text-white placeholder:text-zinc-600 focus-visible:ring-yellow-400 focus-visible:border-yellow-400 rounded-xl h-12"
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-widest text-zinc-500">Password</label>
              <div className="relative mt-2">
                <Input
                  data-testid="login-password"
                  type={show ? "text" : "password"}
                  value={password}
                  required
                  minLength={6}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  className="bg-zinc-900/70 border-zinc-800 text-white placeholder:text-zinc-600 focus-visible:ring-yellow-400 focus-visible:border-yellow-400 rounded-xl h-12 pr-12"
                />
                <button type="button" onClick={() => setShow(s => !s)} data-testid="toggle-password"
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-zinc-500 hover:text-yellow-400">
                  {show ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                </button>
              </div>
            </div>

            {error && (
              <div data-testid="login-error" className="text-sm text-red-400 bg-red-500/10 border border-red-500/20 px-3 py-2 rounded-lg">
                {error}
              </div>
            )}

            <Button
              data-testid="login-submit"
              type="submit"
              disabled={busy}
              className="w-full h-12 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl transition-all duration-200 hover:-translate-y-0.5"
            >
              {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : "Sign in"}
            </Button>

            <div className="text-xs text-zinc-500 text-center pt-2">
              Need an account? Ask your admin to invite you.
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
