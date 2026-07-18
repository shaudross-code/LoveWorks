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
      <header className="sticky top-0 z-40 bg-black/85 backdrop-blur-xl border-b border-yellow-400/15">
        <div className="mx-auto max-w-5xl px-4 sm:px-8 py-3 flex items-center gap-3">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 sm:w-9 sm:h-9 rounded-xl bg-gradient-to-br from-pink-400 to-rose-500 text-white grid place-items-center shadow-md shadow-pink-500/30"><Heart className="w-4 h-4 sm:w-5 sm:h-5 fill-white" /></div>
            <div>
              <div className="font-display font-bold leading-none text-sm sm:text-base">LoveWorks</div>
              <div className="hidden sm:block text-[10px] text-zinc-500 uppercase tracking-widest mt-0.5">Workspace</div>
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
          <div className="ml-auto flex items-center gap-2 sm:gap-3">
            <NotificationBell />
            <NavLink to="/worker/profile" data-testid="topbar-avatar-link" className="flex items-center gap-2 hover:opacity-90 transition">
              <div className="hidden sm:block text-right">
                <div className="text-sm font-medium" data-testid="worker-user-name">{user?.name}</div>
                <div className="text-xs text-zinc-500">{user?.email}</div>
              </div>
              <Avatar url={user?.avatar_url} name={user?.name} size={32} className="ring-2 ring-yellow-400/30 sm:!w-9 sm:!h-9" />
            </NavLink>
            <button data-testid="logout-btn" onClick={async () => { await logout(); nav("/login"); }}
              className="inline-flex items-center gap-1.5 px-2.5 sm:px-3 h-8 sm:h-9 rounded-full sm:rounded-lg bg-zinc-900 hover:bg-zinc-800 border border-yellow-400/10 text-xs sm:text-sm">
              <LogOut className="w-3.5 h-3.5 sm:w-4 sm:h-4" /> <span className="hidden xs:inline">Logout</span>
            </button>
          </div>
        </div>
        {/* Mobile nav row — horizontally scrollable */}
        <div className="sm:hidden border-t border-yellow-400/5 mx-auto max-w-5xl px-4 py-2">
          <div className="-mx-1 flex gap-2 overflow-x-auto no-scrollbar">
            {items.map(({ to, label, icon: Icon, testid }) => (
              <NavLink key={to} to={to} end={to === "/worker"} data-testid={`m-${testid}`}
                className={({ isActive }) =>
                  `shrink-0 inline-flex items-center gap-1.5 px-3 h-8 rounded-full text-xs border whitespace-nowrap ${
                    isActive ? "bg-pink-400 text-white border-pink-400" : "border-yellow-400/20 text-zinc-300"
                  }`
                }
              >
                <Icon className="w-3.5 h-3.5" /> {label}
              </NavLink>
            ))}
          </div>
        </div>
      </header>
      <main className="mx-auto max-w-5xl px-4 sm:px-8 py-6 sm:py-8 md:py-12">{children}</main>
    </div>
  );
}
