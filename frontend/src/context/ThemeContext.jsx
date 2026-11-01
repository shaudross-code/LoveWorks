import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import api from "@/lib/api";
import { useAuth } from "@/context/AuthContext";

const ThemeContext = createContext({ state: null, refresh: () => {}, setMode: async () => {} });

// sessionStorage.forceTheme lets screenshot tooling preview a look in this tab only, without touching anyone's setting
const forcedTheme = () => (typeof sessionStorage !== "undefined" ? sessionStorage.getItem("forceTheme") : null);

export function ThemeProvider({ children }) {
  const { user } = useAuth();
  const [raw, setRaw] = useState(null);

  const refresh = useCallback(async () => {
    try { const { data } = await api.get("/theme"); setRaw(data); }
    catch { setRaw((s) => s || { mode: "auto", effective: "default", theme: null, themes: [] }); }
  }, []);

  useEffect(() => { refresh(); }, [refresh, user?.id]);

  const state = useMemo(() => {
    const forced = forcedTheme();
    if (!raw || !forced) return raw;
    const theme = forced === "default" ? null : (raw.themes || []).find((t) => t.key === forced) || null;
    return { ...raw, effective: forced, theme };
  }, [raw]);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", state?.effective || "default");
  }, [state?.effective]);

  const setMode = useCallback(async (mode) => {
    const { data } = await api.put("/theme", { mode });
    setRaw(data);
    return data;
  }, []);

  const value = useMemo(() => ({ state, refresh, setMode }), [state, refresh, setMode]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export const useTheme = () => useContext(ThemeContext);
