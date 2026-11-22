import { useCallback, useState } from "react";

// One dialog that shows different bodies; `mode`/`item` survive the close animation.
export function useDialogState() {
  const [state, setState] = useState({ open: false });
  const open = useCallback((mode, item = null) => setState({ open: true, mode, item, key: Date.now() }), []);
  const close = useCallback(() => setState((s) => ({ ...s, open: false })), []);
  return { state, open, close };
}
