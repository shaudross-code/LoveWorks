import { User } from "lucide-react";

const BACKEND_URL = process.env.REACT_APP_BACKEND_URL;

/**
 * <Avatar url="/api/files/..." name="Sam" size={40} />
 * Renders an image (with ?auth=<token>) or initials placeholder.
 */
export default function Avatar({ url, name = "", size = 40, className = "" }) {
  const dim = { width: size, height: size };
  const initial = (name?.trim()?.[0] || "?").toUpperCase();
  const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;
  const src = url ? `${BACKEND_URL}${url}${token ? `?auth=${token}` : ""}` : null;

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
