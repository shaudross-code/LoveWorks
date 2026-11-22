import { User } from "lucide-react";
import { fileUrl } from "@/lib/api";

// <Avatar url="/api/files/..." name="Sam" size={40} /> shows the photo or the first initial.
export default function Avatar({ url, name = "", size = 40, className = "" }) {
  const dim = { width: size, height: size };
  const initial = (name?.trim()?.[0] || "?").toUpperCase();
  const src = fileUrl(url);

  return (
    <div
      style={dim}
      className={`relative shrink-0 rounded-full overflow-hidden bg-yellow-400 text-black grid place-items-center font-display font-bold ${className}`}
    >
      {src ? (
        <img
          src={src}
          alt={name}
          style={dim}
          className="object-cover w-full h-full"
          onError={(e) => { e.currentTarget.style.display = "none"; }}
        />
      ) : initial !== "?" ? (
        <span style={{ fontSize: size * 0.42 }}>{initial}</span>
      ) : (
        <User style={{ width: size * 0.55, height: size * 0.55 }} />
      )}
    </div>
  );
}
