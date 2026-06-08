import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "@/context/AuthContext";
import Avatar from "@/components/Avatar";
import NotificationBell from "@/components/NotificationBell";
import { LayoutDashboard, Users, ClipboardList, BadgeDollarSign, LogOut, ChevronRight, UserCircle2, Target, Megaphone, Plane, ShoppingBag } from "lucide-react";

const items = [
  { to: "/admin",                label: "Overview",       icon: LayoutDashboard, testid: "nav-overview" },
  { to: "/admin/workers",        label: "Workers",        icon: Users,           testid: "nav-workers" },
  { to: "/admin/tasks",          label: "Tasks",          icon: ClipboardList,   testid: "nav-tasks" },
  { to: "/admin/goals",          label: "Goals",          icon: Target,          testid: "nav-goals" },
  { to: "/admin/trips",          label: "Trips",          icon: Plane,           testid: "nav-trips" },
  { to: "/admin/essentials",     label: "Essentials",     icon: ShoppingBag,     testid: "nav-essentials" },
  { to: "/admin/payroll",        label: "Payroll",        icon: BadgeDollarSign, testid: "nav-payroll" },
  { to: "/admin/announcements",  label: "Announcements",  icon: Megaphone,       testid: "nav-announcements" },
  { to: "/admin/profile",        label: "Profile",        icon: UserCircle2,     testid: "nav-profile" },
];

export default function AdminLayout({ children }) {
  const { user, logout } = useAuth();
  const nav = useNavigate();

  return (
    <div className="min-h-screen bg-[#09090B] text-white flex">
      <aside className="hidden md:flex w-64 shrink-0 flex-col border-r border-yellow-400/15 bg-[#0c0c0e] sticky top-0 h-screen">
        <div className="px-6 pt-8 pb-6 border-b border-yellow-400/10">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-yellow-400 text-black grid place-items-center font-display font-bold text-lg">C</div>
            <div className="flex-1 min-w-0">
              <div className="font-display font-bold text-lg leading-none">LoveWorks</div>
              <div className="text-xs text-zinc-500 mt-1 uppercase tracking-widest">Admin Console</div>
            </div>
            <NotificationBell />
          </div>
        </div>
        <nav className="flex-1 px-3 py-5 space-y-1">
          {items.map(({ to, label, icon: Icon, testid }) => (
            <NavLink
              key={to}
              to={to}
              end={to === "/admin"}
              data-testid={testid}
              className={({ isActive }) =>
                `group flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200 ${
                  isActive
                    ? "bg-yellow-400/10 text-yellow-400 ring-1 ring-yellow-400/30"
                    : "text-zinc-400 hover:text-white hover:bg-white/5"
                }`
              }
            >
              <Icon className="w-5 h-5" />
              <span className="font-medium">{label}</span>
              <ChevronRight className="w-4 h-4 ml-auto opacity-0 group-hover:opacity-60 transition" />
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-yellow-400/10">
          <NavLink to="/admin/profile" data-testid="sidebar-avatar-link" className="px-3 py-3 rounded-xl bg-zinc-900/60 hover:bg-zinc-900 transition flex items-center gap-3">
            <Avatar url={user?.avatar_url} name={user?.name} size={40} className="ring-2 ring-yellow-400/30" />
            <div className="min-w-0 flex-1">
              <div className="text-[10px] text-zinc-500 uppercase tracking-widest">Signed in</div>
              <div className="font-medium truncate" data-testid="admin-user-name">{user?.name || user?.email}</div>
            </div>
          </NavLink>
          <button
            data-testid="logout-btn"
            onClick={async () => { await logout(); nav("/login"); }}
            className="mt-3 w-full flex items-center justify-center gap-2 px-3 py-2 rounded-lg bg-zinc-800 hover:bg-zinc-700 text-zinc-200 text-sm transition"
          >
            <LogOut className="w-4 h-4" /> Logout
          </button>
        </div>
      </aside>

      {/* Mobile top bar */}
      <div className="md:hidden fixed top-0 inset-x-0 z-40 bg-black/70 backdrop-blur-xl border-b border-yellow-400/10 px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-yellow-400 text-black grid place-items-center font-display font-bold">C</div>
          <div className="font-display font-bold">LoveWorks</div>
        </div>
        <button data-testid="logout-btn-mobile" onClick={async () => { await logout(); nav("/login"); }} className="text-zinc-300 text-sm flex items-center gap-1">
          <LogOut className="w-4 h-4" /> Logout
        </button>
        <div className="ml-2"><NotificationBell /></div>
      </div>
      <div className="md:hidden h-14" />

      <main className="flex-1 min-w-0">
        <div className="mx-auto max-w-6xl px-5 sm:px-8 md:px-10 py-8 md:py-12">
          {/* Mobile nav pills */}
          <div className="md:hidden -mx-1 mb-6 flex gap-2 overflow-x-auto">
            {items.map(({ to, label, icon: Icon, testid }) => (
              <NavLink key={to} to={to} end={to === "/admin"} data-testid={`m-${testid}`}
                className={({ isActive }) =>
                  `shrink-0 inline-flex items-center gap-2 px-3 py-2 rounded-full text-sm border ${
                    isActive ? "bg-yellow-400 text-black border-yellow-400" : "border-yellow-400/20 text-zinc-300"
                  }`
                }
              >
                <Icon className="w-4 h-4" /> {label}
              </NavLink>
            ))}
          </div>
          {children}
        </div>
      </main>
    </div>
  );
}
