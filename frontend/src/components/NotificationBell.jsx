import { useEffect, useRef, useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import api from "@/lib/api";
import { Bell, Check, CheckCheck, Trophy, ClipboardList, Megaphone, Sparkles, AlarmClock, Target, Heart, CheckCircle2, Users, X } from "lucide-react";

const TYPE_ICON = {
  task_assigned:        ClipboardList,
  task_updated:         ClipboardList,
  task_due_soon:        AlarmClock,
  task_completed:       CheckCircle2,
  award:                Trophy,
  announcement:         Megaphone,
  goal_assigned:        Target,
  goal_completed:       Sparkles,
  goal_reaction:        Heart,
  collab_added:         Users,
  peer_access_request:  Users,
  peer_access_response: Users,
};
const TYPE_COLOR = {
  task_assigned:        "text-sky-400 bg-sky-400/10",
  task_updated:         "text-amber-300 bg-amber-300/10",
  task_due_soon:        "text-red-400 bg-red-400/10",
  task_completed:       "text-emerald-400 bg-emerald-400/10",
  award:                "text-yellow-400 bg-yellow-400/10",
  announcement:         "text-emerald-400 bg-emerald-400/10",
  goal_assigned:        "text-fuchsia-400 bg-fuchsia-400/10",
  goal_completed:       "text-yellow-300 bg-yellow-300/10",
  goal_reaction:        "text-pink-400 bg-pink-400/10",
  collab_added:         "text-pink-400 bg-pink-400/10",
  peer_access_request:  "text-pink-400 bg-pink-400/10",
  peer_access_response: "text-emerald-400 bg-emerald-400/10",
};

function timeAgo(iso) {
  if (!iso) return "";
  const s = Math.max(1, Math.floor((Date.now() - new Date(iso).getTime()) / 1000));
  if (s < 60) return `${s}s`;
  if (s < 3600) return `${Math.floor(s / 60)}m`;
  if (s < 86400) return `${Math.floor(s / 3600)}h`;
  return `${Math.floor(s / 86400)}d`;
}

export default function NotificationBell({ align = "right" } = {}) {
  const [items, setItems] = useState([]);
  const [unread, setUnread] = useState(0);
  const [open, setOpen] = useState(false);
  const popRef = useRef(null);
  const nav = useNavigate();

  const load = useCallback(async () => {
    try {
      const { data } = await api.get("/notifications", { params: { limit: 30 } });
      setItems(data.items || []);
      setUnread(data.unread || 0);
    } catch { /* noop */ }
  }, []);

  useEffect(() => {
    load();
    const t = setInterval(load, 45000);
    return () => clearInterval(t);
  }, [load]);

  useEffect(() => {
    const onDoc = (e) => {
      if (popRef.current && !popRef.current.contains(e.target)) setOpen(false);
    };
    if (open) document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  const markAllRead = async () => {
    try { await api.post("/notifications/read-all"); load(); } catch { /* noop */ }
  };
  const respondPeer = async (n, accept) => {
    const reqId = n.meta?.request_id;
    if (!reqId) return;
    try {
      await api.post(`/peer-access/${reqId}/respond`, { accept });
      await api.post(`/notifications/${n.id}/read`);
      load();
    } catch { /* noop */ }
  };
  const onItemClick = async (n) => {
    if (!n.read) { try { await api.post(`/notifications/${n.id}/read`); } catch { /* noop */ } }
    setOpen(false);
    if (n.link) nav(n.link);
    load();
  };

  return (
    <div className="relative" ref={popRef}>
      <button
        data-testid="notification-bell"
        onClick={() => setOpen((v) => !v)}
        className="relative inline-flex items-center justify-center w-10 h-10 rounded-full bg-zinc-900 hover:bg-zinc-800 border border-yellow-400/15 transition"
        aria-label="Notifications"
      >
        <Bell className="w-4 h-4 text-zinc-200" />
        {unread > 0 && (
          <span data-testid="notif-unread-count"
            className="absolute -top-1 -right-1 min-w-[18px] h-[18px] px-1 rounded-full bg-yellow-400 text-black text-[10px] font-bold grid place-items-center ring-2 ring-[#0c0c0e]">
            {unread > 9 ? "9+" : unread}
          </span>
        )}
      </button>
      {open && (
        <div data-testid="notification-panel"
          className={`absolute ${align === "left" ? "left-0" : "right-0"} mt-2 w-[min(360px,calc(100vw-2rem))] max-h-[480px] overflow-hidden rounded-2xl bg-[#0f0f12] border border-yellow-400/20 shadow-2xl z-[60]`}>
          <div className="px-4 py-3 border-b border-yellow-400/10 flex items-center justify-between">
            <div className="font-display font-semibold">Notifications</div>
            {unread > 0 && (
              <button data-testid="mark-all-read" onClick={markAllRead}
                className="inline-flex items-center gap-1 text-xs text-yellow-400 hover:underline">
                <CheckCheck className="w-3.5 h-3.5" /> Mark all read
              </button>
            )}
          </div>
          <div className="overflow-y-auto max-h-[400px] divide-y divide-yellow-400/5">
            {items.length === 0 && (
              <div className="px-4 py-10 text-center text-sm text-zinc-500">
                <Sparkles className="w-6 h-6 mx-auto text-yellow-400 mb-2" />
                You're all caught up.
              </div>
            )}
            {items.map((n) => {
              const Icon = TYPE_ICON[n.type] || Bell;
              const cls = TYPE_COLOR[n.type] || "text-zinc-300 bg-zinc-800";
              return (
                <button
                  key={n.id}
                  data-testid={`notif-${n.id}`}
                  onClick={() => onItemClick(n)}
                  className={`w-full text-left px-4 py-3 flex items-start gap-3 hover:bg-white/[0.03] transition ${
                    !n.read ? "bg-yellow-400/[0.04]" : ""
                  }`}
                >
                  <div className={`shrink-0 w-9 h-9 rounded-xl grid place-items-center ${cls}`}>
                    <Icon className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <div className={`text-sm font-medium ${!n.read ? "text-white" : "text-zinc-300"}`}>{n.title}</div>
                      {!n.read && <span className="w-1.5 h-1.5 rounded-full bg-yellow-400" />}
                    </div>
                    {n.body && <div className="text-xs text-zinc-400 mt-0.5 line-clamp-2">{n.body}</div>}
                    <div className="text-[10px] text-zinc-500 mt-1 uppercase tracking-widest">{timeAgo(n.created_at)} ago</div>
                    {n.type === "peer_access_request" && n.meta?.request_id && (
                      <div className="mt-2 flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                        <button data-testid={`peer-accept-${n.meta.request_id}`}
                          onClick={(e) => { e.stopPropagation(); respondPeer(n, true); }}
                          className="inline-flex items-center gap-1 px-2.5 h-7 rounded-full bg-emerald-500 hover:bg-emerald-400 text-black text-xs font-semibold">
                          <Check className="w-3 h-3" /> Accept
                        </button>
                        <button data-testid={`peer-decline-${n.meta.request_id}`}
                          onClick={(e) => { e.stopPropagation(); respondPeer(n, false); }}
                          className="inline-flex items-center gap-1 px-2.5 h-7 rounded-full bg-zinc-800 hover:bg-zinc-700 text-zinc-200 text-xs">
                          <X className="w-3 h-3" /> Decline
                        </button>
                      </div>
                    )}
                  </div>
                  {!n.read && <Check className="w-4 h-4 text-zinc-500 mt-1" />}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
