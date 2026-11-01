import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import api from "@/lib/api";
import { useAuth } from "@/context/AuthContext";

const ThemeContext = createContext({ state: null, refresh: () => {}, setMode: async () => {} });

export function ThemeProvider({ children }) {
  const { user } = useAuth();
  const [state, setState] = useState(null);

  const refresh = useCallback(async () => {
    try { const { data } = await api.get("/theme"); setState(data); }
    catch { setState((s) => s || { mode: "auto", effective: "default", theme: null }); }
  }, []);

  useEffect(() => { refresh(); }, [refresh, user?.id]);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", state?.effective || "default");
  }, [state?.effective]);

  const setMode = useCallback(async (mode) => {
    const { data } = await api.put("/theme", { mode });
    setState(data);
    return data;
  }, []);

  const value = useMemo(() => ({ state, refresh, setMode }), [state, refresh, setMode]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export const useTheme = () => useContext(ThemeContext);
