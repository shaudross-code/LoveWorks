import { useCallback, useEffect, useMemo, useState } from "react";
import api from "@/lib/api";

// Loads a list (goals, trips, essentials) plus the people it can be shared with.
export function useOwnedList(path, isAdmin) {
  const [items, setItems] = useState([]);
  const [workers, setWorkers] = useState([]);

  const load = useCallback(async () => {
    const { data } = await api.get(path);
    setItems(data);
    try {
      setWorkers((await api.get(isAdmin ? "/workers" : "/peers")).data);
    } catch { /* workers list unavailable */ }
  }, [path, isAdmin]);

  useEffect(() => { load(); }, [load]);

  return { items, setItems, workers, load };
}

// "View by worker" filter for admins.
export function useOwnerScope(items, isAdmin) {
  const [owner, setOwner] = useState("all");
  const scoped = useMemo(
    () => (!isAdmin || owner === "all" ? items : items.filter((i) => i.owner_id === owner)),
    [items, isAdmin, owner],
  );
  return { owner, setOwner, scoped };
}
