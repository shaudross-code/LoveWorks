import { useEffect } from "react";

// Calls onClose when the user presses outside `ref` while `active`.
export function useOutsideClose(ref, active, onClose, eventName = "pointerdown") {
  useEffect(() => {
    if (!active) return undefined;
    const onDoc = (e) => { if (ref.current && !ref.current.contains(e.target)) onClose(); };
    document.addEventListener(eventName, onDoc);
    return () => document.removeEventListener(eventName, onDoc);
  }, [ref, active, onClose, eventName]);
}
