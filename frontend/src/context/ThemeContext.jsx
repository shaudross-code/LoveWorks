import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import api from "@/lib/api";
import { useAuth } from "@/context/AuthContext";

const ThemeContext = createContext({ state: null, refresh: () => {}, setMode: async () => {} });
const CACHE_KEY = "lastTheme";
const RETRY_MS = 20000;
const POLL_MS = 30 * 60 * 1000;

// sessionStorage.forceTheme lets screenshot tooling preview a look in this tab only, without touching anyone's setting
const forcedTheme = () => (typeof sessionStorage !== "undefined" ? sessionStorage.getItem("forceTheme") : null);

const todayISO = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
};

// Last theme the server sent, dropped once its holiday window has ended
const readCache = () => {
  try {
    const s = JSON.parse(localStorage.getItem(CACHE_KEY));
    if (!s?.effective) return null;
    if (s.ends_on && todayISO() > s.ends_on) return { ...s, effective: "default", theme: null };
    return s;
  } catch { return null; }
};

const applyTheme = (key) => document.documentElement.setAttribute("data-theme", key || "default");

// Apply before React's first paint so the app never flashes the default look
applyTheme(forcedTheme() || readCache()?.effective);

export function ThemeProvider({ children }) {
  const { user } = useAuth();
  const [raw, setRaw] = useState(readCache);
  const retry = useRef(null);

  const save = useCallback((data) => {
    setRaw(data);
    try { localStorage.setItem(CACHE_KEY, JSON.stringify(data)); } catch { /* storage full or blocked */ }
  }, []);

  const refresh = useCallback(async () => {
    clearTimeout(retry.current);
    try { const { data } = await api.get("/theme"); save(data); }
    catch {
      setRaw((s) => s || readCache() || { mode: "auto", effective: "default", theme: null, themes: [] });
      retry.current = setTimeout(() => refresh(), RETRY_MS);
    }
  }, [save]);

  useEffect(() => { refresh(); }, [refresh, user?.id]);

  useEffect(() => {
    const onVisible = () => { if (document.visibilityState === "visible") refresh(); };
    document.addEventListener("visibilitychange", onVisible);
    window.addEventListener("focus", refresh);
    const poll = setInterval(refresh, POLL_MS);
    return () => {
      document.removeEventListener("visibilitychange", onVisible);
      window.removeEventListener("focus", refresh);
      clearInterval(poll);
      clearTimeout(retry.current);
    };
  }, [refresh]);

  const state = useMemo(() => {
    const forced = forcedTheme();
    if (!raw || !forced) return raw;
    const theme = forced === "default" ? null : (raw.themes || []).find((t) => t.key === forced) || null;
    return { ...raw, effective: forced, theme };
  }, [raw]);

  useEffect(() => { applyTheme(state?.effective); }, [state?.effective]);

  const setMode = useCallback(async (mode) => {
    const { data } = await api.put("/theme", { mode });
    save(data);
    return data;
  }, [save]);

  const value = useMemo(() => ({ state, refresh, setMode }), [state, refresh, setMode]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export const useTheme = () => useContext(ThemeContext);
