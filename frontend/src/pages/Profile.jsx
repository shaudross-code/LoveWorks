import { useRef, useState } from "react";
import { useAuth } from "@/context/AuthContext";
import api, { formatApiError } from "@/lib/api";
import Avatar from "@/components/Avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Camera, Loader2, Save, Trash2, User } from "lucide-react";
import { toast } from "sonner";
import { PushSettings } from "@/components/PushPrompt";

export default function Profile() {
  const { user, setUser } = useAuth();
  const fileRef = useRef(null);
  const [name, setName] = useState(user?.name || "");
  const [busy, setBusy] = useState(false);
  const [uploading, setUploading] = useState(false);

  const saveName = async (e) => {
    e?.preventDefault?.();
    const trimmed = name.trim();
    if (!trimmed) { toast.error("Name can't be empty"); return; }
    if (trimmed === user.name) { toast.message("No changes"); return; }
    setBusy(true);
    try {
      const { data } = await api.patch("/me/profile", { name: trimmed });
      setUser(data);
      toast.success("Name updated");
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setBusy(false); }
  };

  const pickFile = () => fileRef.current?.click();

  const onFile = async (e) => {
    const f = e.target.files?.[0];
    e.target.value = ""; // allow re-uploading same file
    if (!f) return;
    if (!/^image\/(png|jpe?g|webp|gif)$/i.test(f.type)) { toast.error("Pick a PNG, JPEG, WEBP, or GIF image"); return; }
    if (f.size > 3 * 1024 * 1024) { toast.error("Image too large (max 3 MB)"); return; }
    setUploading(true);
    try {
      const form = new FormData();
      form.append("file", f);
      const { data } = await api.post("/me/avatar", form, { headers: { "Content-Type": "multipart/form-data" } });
      setUser(data);
      toast.success("Profile picture updated");
    } catch (e) { toast.error(formatApiError(e)); }
    finally { setUploading(false); }
  };

  const removeAvatar = async () => {
    if (!user?.avatar_url) return;
    if (!window.confirm("Remove your profile picture?")) return;
    try {
      const { data } = await api.delete("/me/avatar");
      setUser(data);
      toast.success("Profile picture removed");
    } catch (e) { toast.error(formatApiError(e)); }
  };

  return (
    <div className="space-y-8">
      <div>
        <div className="text-xs uppercase tracking-widest text-yellow-400">Profile</div>
        <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-2">Your account.</h1>
        <p className="mt-2 text-zinc-400">Polish your name and add a face to the gold.</p>
      </div>

      <div className="bg-[#121214] border border-yellow-400/15 rounded-2xl p-6 sm:p-8">
        <div className="flex flex-col sm:flex-row gap-6 sm:items-center">
          <div className="relative">
            <Avatar url={user?.avatar_url} name={user?.name} size={120} className="ring-2 ring-yellow-400/30" />
            <button
              data-testid="avatar-upload-btn"
              type="button"
              onClick={pickFile}
              disabled={uploading}
              className="absolute -bottom-1 -right-1 w-10 h-10 rounded-full bg-yellow-400 hover:bg-yellow-300 text-black grid place-items-center border-4 border-[#121214] transition"
              aria-label="Change profile picture"
            >
              {uploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Camera className="w-4 h-4" />}
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="image/png,image/jpeg,image/webp,image/gif"
              data-testid="avatar-file-input"
              onChange={onFile}
              className="hidden"
            />
          </div>

          <div className="flex-1 min-w-0">
            <div className="text-xs uppercase tracking-widest text-zinc-500">Signed in as</div>
            <div className="font-display text-2xl font-semibold mt-1 truncate" data-testid="profile-email">{user?.email}</div>
            <div className="mt-1 inline-flex items-center gap-1 text-xs px-2 py-0.5 rounded-full bg-yellow-400/10 text-yellow-300 capitalize">
              <User className="w-3 h-3" /> {user?.role}
            </div>
            {user?.avatar_url && (
              <button
                data-testid="avatar-remove-btn"
                onClick={removeAvatar}
                className="mt-4 inline-flex items-center gap-1 text-sm text-zinc-400 hover:text-red-400 transition"
              >
                <Trash2 className="w-3.5 h-3.5" /> Remove picture
              </button>
            )}
          </div>
        </div>

        <form onSubmit={saveName} className="mt-8 grid sm:grid-cols-[1fr_auto] gap-3 items-end max-w-xl">
          <div>
            <label className="text-xs uppercase tracking-widest text-zinc-500">Display name</label>
            <Input
              data-testid="profile-name-input"
              value={name}
              onChange={(e) => setName(e.target.value)}
              maxLength={80}
              className="mt-2 bg-zinc-900 border-zinc-800 text-white rounded-xl h-12"
              placeholder="Your name"
            />
          </div>
          <Button
            data-testid="profile-save-btn"
            type="submit"
            disabled={busy}
            className="h-12 bg-yellow-400 hover:bg-yellow-300 text-black font-semibold rounded-xl px-5"
          >
            {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <><Save className="w-4 h-4 mr-2" /> Save</>}
          </Button>
        </form>

        <div className="mt-8 pt-6 border-t border-yellow-400/10">
          <div className="text-xs uppercase tracking-widest text-zinc-500">Notifications</div>
          <div className="mt-2 text-sm text-zinc-400 max-w-xl">
            Get push pings 30 minutes before a task is due, plus instant alerts when admin assigns you a new task, goal, or announcement — even when ClockWork is closed.
          </div>
          <div className="mt-3">
            <PushSettings />
          </div>
        </div>
      </div>
    </div>
  );
}
