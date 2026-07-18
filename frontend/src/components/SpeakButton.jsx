import { useEffect, useRef, useState } from "react";
import { Volume2, Square } from "lucide-react";

/**
 * Tiny click-to-read button using window.speechSynthesis.
 * Click → reads `text`. Click again → stops. Speaks at most one button at a time.
 */
export default function SpeakButton({ text, label = "Read aloud", className = "", size = 16, testid }) {
  const [speaking, setSpeaking] = useState(false);
  const utterRef = useRef(null);
  const supported = typeof window !== "undefined" && "speechSynthesis" in window;

  useEffect(() => {
    return () => {
      // stop on unmount
      if (utterRef.current && supported) {
        window.speechSynthesis.cancel();
      }
    };
  }, [supported]);

  const stop = () => {
    if (!supported) return;
    window.speechSynthesis.cancel();
    setSpeaking(false);
    utterRef.current = null;
  };

  const speak = () => {
    if (!supported || !text) return;
    if (speaking) { stop(); return; }
    // Cancel any other in-flight speech first
    window.speechSynthesis.cancel();
    const u = new SpeechSynthesisUtterance(text);
    u.rate = 1.0;
    u.pitch = 1.0;
    u.volume = 1.0;
    // Prefer an English voice if available
    const voices = window.speechSynthesis.getVoices?.() || [];
    const preferred = voices.find((v) => /en[-_]/i.test(v.lang)) || voices[0];
    if (preferred) u.voice = preferred;
    u.onend = () => { setSpeaking(false); utterRef.current = null; };
    u.onerror = () => { setSpeaking(false); utterRef.current = null; };
    utterRef.current = u;
    setSpeaking(true);
    window.speechSynthesis.speak(u);
  };

  if (!supported) return null;

  return (
    <button
      type="button"
      data-testid={testid}
      aria-label={speaking ? "Stop reading" : label}
      onClick={(e) => { e.stopPropagation(); speak(); }}
      title={speaking ? "Stop" : label}
      className={`inline-flex items-center justify-center rounded-full border transition shrink-0 ${
        speaking
          ? "bg-yellow-400 text-black border-yellow-400 animate-pulse"
          : "bg-zinc-900 text-yellow-400 border-yellow-400/30 hover:bg-yellow-400/10 hover:border-yellow-400/60"
      } ${className}`}
      style={{ width: size + 14, height: size + 14 }}
    >
      {speaking ? <Square style={{ width: size - 4, height: size - 4 }} fill="currentColor" /> : <Volume2 style={{ width: size, height: size }} />}
    </button>
  );
}
