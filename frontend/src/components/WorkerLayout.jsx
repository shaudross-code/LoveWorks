import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import Avatar from "@/components/Avatar";
import NotificationBell from "@/components/NotificationBell";
import { Clock, History, LogOut, UserCircle2, Trophy, Megaphone, ShoppingBag, Plane, Heart } from "lucide-react";

const items = [
  { to: "/worker",                label: "Workday",      icon: Clock,        testid: "nav-workday" },
  { to: "/worker/history",        label: "History",      icon: History,      testid: "nav-history" },
  { to: "/worker/trips",          label: "Trips",        icon: Plane,        testid: "nav-trips" },
  { to: "/worker/essentials",     label: "Essentials",   icon: ShoppingBag,  testid: "nav-essentials" },
  { to: "/worker/awards",         label: "Awards",       icon: Trophy,       testid: "nav-awards" },
  { to: "/worker/announcements",  label: "What's new",   icon: Megaphone,    testid: "nav-announcements" },
  { to: "/worker/profile",        label: "Profile",      icon: UserCircle2,  testid: "nav-profile" },
];

export default function WorkerLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();

  return (
    <div className="min-h-screen bg-[#09090B] text-white">
      <header className="sticky top-0 z-40 bg-black/70 backdrop-blur-xl border-b border-yellow-400/15">
        <div className="mx-auto max-w-5xl px-5 sm:px-8 py-3 flex items-center gap-3">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-pink-400 to-rose-500 text-white grid place-items-center shadow-md shadow-pink-500/30"><Heart className="w-5 h-5 fill-white" /></div>
            <div>
              <div className="font-display font-bold leading-none">LoveWorks</div>
              <div className="text-[10px] text-zinc-500 uppercase tracking-widest mt-0.5">Workspace</div>
            </div>
          </div>
          <nav className="ml-6 hidden sm:flex items-center gap-1">
            {items.map(({ to, label, icon: Icon, testid }) => (
              <NavLink key={to} to={to} end={to === "/worker"} data-testid={testid}
                className={({ isActive }) =>
                  `inline-flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition ${
                    isActive ? "bg-pink-400/10 text-pink-300" : "text-zinc-400 hover:text-white hover:bg-white/5"
                  }`
                }
              >
                <Icon className="w-4 h-4" /> {label}
              </NavLink>
            ))}
          </nav>
          <div className="ml-auto flex items-center gap-3">
            <NotificationBell />
            <NavLink to="/worker/profile" data-testid="topbar-avatar-link" className="flex items-center gap-2 hover:opacity-90 transition">
              <div className="hidden sm:block text-right">
                <div className="text-sm font-medium" data-testid="worker-user-name">{user?.name}</div>
                <div className="text-xs text-zinc-500">{user?.email}</div>
              </div>
              <Avatar url={user?.avatar_url} name={user?.name} size={36} className="ring-2 ring-yellow-400/30" />
            </NavLink>
            <button data-testid="logout-btn" onClick={async () => { await logout(); nav("/login"); }}
              className="inline-flex items-center gap-2 px-3 py-2 rounded-lg bg-zinc-900 hover:bg-zinc-800 border border-yellow-400/10 text-sm">
              <LogOut className="w-4 h-4" /> Logout
            </button>
          </div>
        </div>
        {/* Mobile nav row */}
        <div className="sm:hidden mx-auto max-w-5xl px-5 pb-3 flex gap-2">
          {items.map(({ to, label, icon: Icon, testid }) => (
            <NavLink key={to} to={to} end={to === "/worker"} data-testid={`m-${testid}`}
              className={({ isActive }) =>
                `flex-1 inline-flex items-center justify-center gap-2 px-3 py-2 rounded-lg text-sm border ${
                  isActive ? "bg-yellow-400 text-black border-yellow-400" : "border-yellow-400/20 text-zinc-300"
                }`
              }
            >
              <Icon className="w-4 h-4" /> {label}
            </NavLink>
          ))}
        </div>
      </header>
      <main className="mx-auto max-w-5xl px-5 sm:px-8 py-8 md:py-12">{children}</main>
    </div>
  );
}
