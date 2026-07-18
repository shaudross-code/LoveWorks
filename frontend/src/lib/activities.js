import { Briefcase, BookOpen, Coffee, Sparkles, Dumbbell, Baby, HeartPulse } from "lucide-react";

export const ACTIVITIES = [
  { key: "working",   label: "Working",   icon: Briefcase, color: "yellow",  ring: "ring-yellow-400/40",  bg: "bg-yellow-400",       text: "text-black",     pill: "bg-yellow-400/15 text-yellow-300" },
  { key: "studying",  label: "Studying",  icon: BookOpen,  color: "sky",     ring: "ring-sky-400/40",     bg: "bg-sky-400",          text: "text-black",     pill: "bg-sky-400/15 text-sky-300" },
  { key: "break",     label: "Break",     icon: Coffee,    color: "zinc",    ring: "ring-zinc-400/40",    bg: "bg-zinc-300",         text: "text-black",     pill: "bg-zinc-700 text-zinc-200" },
  { key: "cleaning",  label: "Cleaning",  icon: Sparkles,  color: "emerald", ring: "ring-emerald-400/40", bg: "bg-emerald-400",      text: "text-black",     pill: "bg-emerald-400/15 text-emerald-300" },
  { key: "workout",   label: "Workout",   icon: Dumbbell,  color: "orange",  ring: "ring-orange-400/40",  bg: "bg-orange-400",       text: "text-black",     pill: "bg-orange-400/15 text-orange-300" },
  { key: "parenting", label: "Parenting", icon: Baby,      color: "pink",    ring: "ring-pink-400/40",    bg: "bg-pink-400",         text: "text-black",     pill: "bg-pink-400/15 text-pink-300" },
  { key: "self_care", label: "Self Care", icon: HeartPulse,color: "rose",    ring: "ring-rose-400/40",    bg: "bg-rose-400",         text: "text-black",     pill: "bg-rose-400/15 text-rose-300" },
];

export const ACTIVITY_MAP = Object.fromEntries(ACTIVITIES.map(a => [a.key, a]));

export function activityOf(key) {
  return ACTIVITY_MAP[key] || ACTIVITIES[0];
}
