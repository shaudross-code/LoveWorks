import { useEffect, useState } from "react";
import { useNavigate, useLocation } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Eye, EyeOff, Loader2, ShieldCheck } from "lucide-react";

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
      {/* Decorative gold gradient */}
      <div className="absolute -top-40 -left-40 w-[520px] h-[520px] bg-yellow-400/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-0 right-0 w-[460px] h-[460px] bg-yellow-500/5 rounded-full blur-3xl pointer-events-none" />

      {/* Left: brand */}
      <div className="hidden lg:flex flex-1 flex-col justify-between p-12 border-r border-yellow-400/10 relative">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-yellow-400 text-black grid place-items-center font-display font-extrabold text-xl">C</div>
          <div>
            <div className="font-display text-2xl font-bold leading-none">ClockWork</div>
            <div className="text-xs text-zinc-500 mt-1 uppercase tracking-widest">Time · Tasks · Pay</div>
          </div>
        </div>
        <div>
          <h1 className="font-display text-5xl xl:text-6xl font-bold tracking-tight leading-[1.05]">
            Run your crew. <br />
            <span className="text-yellow-400">Reward the hustle.</span>
          </h1>
          <p className="mt-6 max-w-md text-zinc-400 text-base leading-relaxed">
            Clock workers in and out, assign tasks with fixed payouts, and watch
            payroll add itself up — all from one charmingly black & gold console.
          </p>
          <div className="mt-10 flex items-center gap-3 text-zinc-500 text-sm">
            <ShieldCheck className="w-4 h-4 text-yellow-400" />
            Secured with JWT · Admin invitations only
          </div>
        </div>
        <div className="text-xs text-zinc-600">© ClockWork — built for foremen with style.</div>
      </div>

      {/* Right: form */}
      <div className="flex-1 flex items-center justify-center p-6 sm:p-12">
        <form onSubmit={onSubmit} className="w-full max-w-md bg-[#121214] border border-yellow-400/15 rounded-2xl p-8 shadow-2xl shadow-yellow-400/5 fade-up">
          <div className="lg:hidden flex items-center gap-2 mb-6">
            <div className="w-9 h-9 rounded-xl bg-yellow-400 text-black grid place-items-center font-display font-bold">C</div>
            <div className="font-display font-bold text-lg">ClockWork</div>
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
