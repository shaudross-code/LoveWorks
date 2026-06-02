import { Sparkles, Hand, Medal, Trophy, Sunrise, Flame, Award as AwardIcon } from "lucide-react";

// Map icon string from backend to a lucide icon + accent color
export const AWARD_VISUAL = {
  "sparkle":       { Icon: Sparkles, accent: "from-yellow-300 to-yellow-500",   text: "text-black" },
  "high-five":     { Icon: Hand,     accent: "from-pink-400 to-rose-500",       text: "text-white" },
  "medal-bronze":  { Icon: Medal,    accent: "from-amber-600 to-amber-800",     text: "text-white" },
  "medal-silver":  { Icon: Medal,    accent: "from-zinc-300 to-zinc-500",       text: "text-black" },
  "medal-gold":    { Icon: Medal,    accent: "from-yellow-300 to-yellow-500",   text: "text-black" },
  "trophy":        { Icon: Trophy,   accent: "from-yellow-300 via-yellow-400 to-amber-500", text: "text-black" },
  "sunrise":       { Icon: Sunrise,  accent: "from-orange-300 to-orange-500",   text: "text-black" },
  "flame":         { Icon: Flame,    accent: "from-orange-400 to-red-500",      text: "text-white" },
  "flame-gold":    { Icon: Flame,    accent: "from-yellow-300 to-orange-500",   text: "text-black" },
  "default":       { Icon: AwardIcon, accent: "from-yellow-300 to-yellow-500",  text: "text-black" },
};

export function visualFor(iconKey) {
  return AWARD_VISUAL[iconKey] || AWARD_VISUAL.default;
}
