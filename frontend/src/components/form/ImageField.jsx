import { useRef } from "react";
import { Image as ImageIcon, Loader2, Trash2, Upload } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { FieldLabel } from "@/components/form/LabeledInput";
import { fileUrl } from "@/lib/api";

const MAX_BYTES = 3 * 1024 * 1024;

// Photo preview with upload / replace / (optional) remove buttons for edit dialogs.
export default function ImageField({ label, imageUrl, alt, busy, onFile, onRemove, testPrefix, replaceLabel = "Replace photo", previewTestid }) {
  const ref = useRef(null);
  const pick = (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (file.size > MAX_BYTES) { toast.error("Image too large (max 3 MB)"); return; }
    onFile(file);
  };
  return (
    <div>
      <FieldLabel icon={ImageIcon}>{label}</FieldLabel>
      <div className="mt-2 flex items-center gap-4">
        <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-zinc-900 border border-yellow-400/20 shrink-0 grid place-items-center">
          {imageUrl ? <img src={fileUrl(imageUrl)} alt={alt} className="w-full h-full object-cover" data-testid={previewTestid} />
            : <ImageIcon className="w-7 h-7 text-zinc-700" />}
        </div>
        <div className="flex flex-wrap gap-2">
          <input ref={ref} type="file" accept="image/jpeg,image/png,image/webp,image/gif" className="hidden"
            onChange={pick} data-testid={`${testPrefix}-input`} />
          <Button data-testid={`${testPrefix}-upload-btn`} type="button" onClick={() => ref.current?.click()} disabled={busy}
            className="bg-yellow-400 hover:bg-yellow-300 text-black rounded-full h-9 px-4 text-sm font-semibold">
            {busy ? <Loader2 className="w-4 h-4 animate-spin mr-1.5" /> : <Upload className="w-4 h-4 mr-1.5" />}
            {imageUrl ? replaceLabel : "Upload photo"}
          </Button>
          {imageUrl && onRemove && (
            <Button data-testid={`${testPrefix}-remove-btn`} type="button" onClick={onRemove} disabled={busy}
              variant="ghost" className="text-zinc-400 hover:text-red-400 hover:bg-red-500/10 rounded-full h-9 px-3 text-sm">
              <Trash2 className="w-4 h-4 mr-1.5" /> Remove
            </Button>
          )}
        </div>
      </div>
      <div className="text-[10px] text-zinc-500 mt-2">JPEG, PNG, WEBP, or GIF — up to 3 MB.</div>
    </div>
  );
}
