export const FITS = [
  { v: "mens", label: "Men's" },
  { v: "womens", label: "Women's" },
  { v: "unspecified", label: "Prefer not to say" },
];
export const FIT_LABEL = Object.fromEntries(FITS.map((f) => [f.v, f.label]));

const LETTER = ["XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"];
const LETTER6 = ["XS", "S", "M", "L", "XL", "XXL"];
const SML = ["S", "M", "L", "XL"];
const BANDS = ["28", "30", "32", "34", "36", "38", "40", "42", "44", "46"];
const CUPS = ["AA", "A", "B", "C", "D", "DD", "DDD", "F", "G", "H"];

const L = (k, label) => ({ k, label, type: "length" });
const C = (k, label, options, fits) => ({ k, label, type: "chips", options, fits });

export const SECTIONS = [
  { key: "body", title: "Body", blurb: "Measured snug, not tight.", fields: [
    L("height", "Height"), { k: "weight", label: "Weight", type: "weight" }, L("neck", "Neck"),
    L("shoulder", "Shoulder width"), L("chest", "Chest / bust"), L("waist", "Waist"), L("hips", "Hips"),
    L("sleeve", "Sleeve length"), L("inseam", "Inseam"), L("head", "Head circumference"), L("hand", "Hand circumference"),
  ] },
  { key: "footwear", title: "Footwear", blurb: "Boots, shoes and width.", fields: [
    { k: "shoe_us", label: "Shoe size", type: "shoe" },
    C("shoe_width", "Width", ["Narrow", "Regular", "Wide", "Extra wide"]),
    { k: "boot_notes", label: "Boot preferences", type: "text", placeholder: "Steel toe, high-top, slip-resistant…" },
  ] },
  { key: "workwear", title: "Workwear", blurb: "Shirts, jackets, pants and gear.", fields: [
    C("top", "Top / T-shirt", LETTER), C("jacket", "Jacket / outerwear", LETTER),
    L("pants_waist", "Pants waist"), L("pants_inseam", "Pants inseam"), C("pants_letter", "Pants (letter size)", LETTER),
    C("gloves", "Gloves", LETTER6), C("hat", "Hat", LETTER6), C("hivis", "Hi-vis vest", LETTER),
  ] },
  { key: "underclothes", title: "Underclothes", blurb: "Only what fits your chosen fit.", fields: [
    C("underwear_style", "Underwear style", ["Briefs", "Boxers", "Boxer briefs", "Trunks"], ["mens"]),
    C("underwear_size", "Underwear size", LETTER, ["mens"]),
    C("undershirt", "Undershirt", LETTER, ["mens"]),
    C("socks", "Sock size", SML, ["mens"]),
    C("bra_band", "Bra band", BANDS, ["womens"]),
    C("bra_cup", "Bra cup", CUPS, ["womens"]),
    C("sports_bra", "Sports bra", LETTER6, ["womens"]),
    C("underwear_style", "Underwear style", ["Briefs", "Bikini", "Boyshort", "Thong"], ["womens"]),
    C("underwear_size", "Underwear size", LETTER, ["womens"]),
    C("leggings", "Leggings / base layer", LETTER6, ["womens"]),
    C("socks", "Sock / hosiery size", SML, ["womens"]),
    C("underwear_size", "Underwear size", LETTER, ["unspecified"]),
    C("base_layer", "Base layer", LETTER6, ["unspecified"]),
    C("socks", "Sock size", SML, ["unspecified"]),
  ] },
  { key: "notes", title: "Fit notes", blurb: "Anything that doesn't fit a box.", fields: [
    { k: "fit_notes", label: "Notes", type: "textarea", placeholder: "Long torso, prefers loose fit, fabric sensitivities…" },
  ] },
];

export const effectiveFit = (fit) => fit || "unspecified";
export const applicable = (field, fit) => !field.fits || field.fits.includes(effectiveFit(fit));
export const sectionFields = (section, fit) => section.fields.filter((f) => applicable(f, fit));

export const fmtNum = (n, d = 1) => (Number.isFinite(n) ? String(+n.toFixed(d)) : "");
export const lengthUnit = (units) => (units === "metric" ? "cm" : "in");
export const weightUnit = (units) => (units === "metric" ? "kg" : "lb");

// canonical cm/kg <-> display units
const toDisplay = (type, cm, units) => {
  if (type === "length") return units === "metric" ? cm : cm / 2.54;
  if (type === "weight") return units === "metric" ? cm : cm * 2.20462;
  return cm;
};
const toCanonical = (type, v, units) => {
  if (type === "length") return units === "metric" ? v : v * 2.54;
  if (type === "weight") return units === "metric" ? v : v / 2.20462;
  return v;
};

// Shoe conversions (men's table for mens/unspecified, women's for womens)
export const SHOE_SCALES = ["US", "EU", "UK"];
const shoeOffsets = (fit) => (effectiveFit(fit) === "womens" ? { uk: -2, eu: 31 } : { uk: -1, eu: 33 });
export function shoeFromUS(us, fit) {
  const o = shoeOffsets(fit);
  return { US: us, UK: us + o.uk, EU: Math.round((us + o.eu) * 2) / 2 };
}
export function shoeToUS(v, scale, fit) {
  const o = shoeOffsets(fit);
  if (scale === "UK") return v - o.uk;
  if (scale === "EU") return v - o.eu;
  return v;
}

const ALL_FIELDS = SECTIONS.flatMap((s) => s.fields);
const typeOf = (k) => ALL_FIELDS.find((f) => f.k === k)?.type || "text";

// Form state keeps display strings; canonical values live on the server.
export function toForm(doc, units) {
  const values = {};
  const fit = doc?.fit || null;
  for (const [k, v] of Object.entries(doc?.values || {})) {
    const t = typeOf(k);
    if (t === "length" || t === "weight") values[k] = fmtNum(toDisplay(t, v, units));
    else if (t === "shoe") values[k] = fmtNum(shoeFromUS(v, fit)[units === "metric" ? "EU" : "US"]);
    else values[k] = String(v);
  }
  return { fit, values, shoeScale: units === "metric" ? "EU" : "US" };
}

export function fromForm(form, units) {
  const out = {};
  for (const [k, raw] of Object.entries(form.values || {})) {
    if (raw === "" || raw == null) continue;
    const t = typeOf(k);
    if (t === "length" || t === "weight" || t === "shoe") {
      const n = parseFloat(raw);
      if (!Number.isFinite(n)) continue;
      out[k] = t === "shoe" ? shoeToUS(n, form.shoeScale, form.fit) : toCanonical(t, n, units);
    } else out[k] = raw;
  }
  return out;
}

export function convertForm(form, fromUnits, toUnits) {
  if (fromUnits === toUnits) return form;
  const values = { ...form.values };
  for (const [k, raw] of Object.entries(values)) {
    const t = typeOf(k);
    if ((t === "length" || t === "weight") && raw !== "") {
      const n = parseFloat(raw);
      if (Number.isFinite(n)) values[k] = fmtNum(toDisplay(t, toCanonical(t, n, fromUnits), toUnits));
    }
  }
  return { ...form, values };
}

export function changeShoeScale(form, scale) {
  const raw = form.values.shoe_us;
  const n = parseFloat(raw);
  const values = { ...form.values };
  if (Number.isFinite(n)) values.shoe_us = fmtNum(shoeFromUS(shoeToUS(n, form.shoeScale, form.fit), form.fit)[scale]);
  return { ...form, values, shoeScale: scale };
}

export function completion(section, form) {
  const fields = sectionFields(section, form.fit);
  const filled = fields.filter((f) => (form.values[f.k] ?? "") !== "").length;
  return { filled, total: fields.length };
}

export const isStale = (iso) => !!iso && Date.now() - new Date(iso).getTime() > 365 * 86400000;
