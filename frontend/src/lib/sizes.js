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
const DRESS = ["00", "0", "2", "4", "6", "8", "10", "12", "14", "16", "18", "20"];

const L = (k, label) => ({ k, label, type: "length" });
const C = (k, label, options, fits) => ({ k, label, type: "chips", options, fits });

export const SECTIONS = [
  { key: "body", title: "Body", blurb: "Measured snug, not tight.", fields: [
    { k: "height", label: "Height", type: "height" }, { k: "weight", label: "Weight", type: "weight" }, L("neck", "Neck"),
    L("shoulder", "Shoulder width"), L("chest", "Chest / bust"), L("waist", "Waist"), L("hips", "Hips"),
    L("sleeve", "Sleeve length"), L("inseam", "Inseam"), L("head", "Head circumference"), L("hand", "Hand circumference"),
  ] },
  { key: "footwear", title: "Footwear", blurb: "Boots, shoes and width.", fields: [
    { k: "shoe_us", label: "Shoe size", type: "shoe" },
    C("shoe_width", "Width", ["Narrow", "Regular", "Wide", "Extra wide"]),
    { k: "boot_notes", label: "Boot preferences", type: "text", placeholder: "Steel toe, high-top, slip-resistant…" },
  ] },
  { key: "casual", title: "Casual fits", blurb: "Everyday clothes off the clock.", fields: [
    C("casual_top", "Casual top / tee", LETTER), C("hoodie", "Hoodie / sweater", LETTER),
    L("jeans_waist", "Jeans waist"), L("jeans_inseam", "Jeans inseam"), C("shorts", "Shorts", LETTER),
    C("dress", "Dress size", DRESS, ["womens"]),
    C("casual_fit", "Preferred fit", ["Slim", "Regular", "Relaxed", "Oversized"]),
  ] },
  { key: "workout", title: "Workout fits", blurb: "Gym, training and team activewear.", fields: [
    C("workout_top", "Workout top", LETTER), C("workout_shorts", "Workout shorts", LETTER),
    C("joggers", "Joggers / sweatpants", LETTER), C("workout_leggings", "Leggings / tights", LETTER6),
    C("compression", "Compression / base layer", LETTER6),
    C("workout_fit", "Preferred fit", ["Fitted", "Regular", "Loose"]),
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
    C("bra_band", "Bra band", BANDS, ["womens", "unspecified"]),
    C("bra_cup", "Bra cup", CUPS, ["womens", "unspecified"]),
    C("sports_bra", "Sports bra", LETTER6, ["womens", "unspecified"]),
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

// canonical cm/kg <-> display units ("height" behaves like a length)
const toDisplay = (type, cm, units) => {
  if (type === "length" || type === "height") return units === "metric" ? cm : cm / 2.54;
  if (type === "weight") return units === "metric" ? cm : cm * 2.20462;
  return cm;
};
const toCanonical = (type, v, units) => {
  if (type === "length" || type === "height") return units === "metric" ? v : v * 2.54;
  if (type === "weight") return units === "metric" ? v : v / 2.20462;
  return v;
};

// Feet & inches helpers (imperial height)
export function ftIn(totalIn) {
  let ft = Math.floor(totalIn / 12);
  let inch = Math.round((totalIn - ft * 12) * 2) / 2;
  if (inch >= 12) { ft += 1; inch = 0; }
  return { ft, inch };
}
const withHeightParts = (values, canon) => {
  if (Number.isFinite(canon.height)) {
    const { ft, inch } = ftIn(canon.height / 2.54);
    return { ...values, height_ft: String(ft), height_in: fmtNum(inch) };
  }
  return { ...values, height_ft: "", height_in: "" };
};
export function setHeightImperial(form, ft, inch) {
  const values = { ...form.values, height_ft: ft, height_in: inch };
  const canon = { ...form.canon };
  const f = parseFloat(ft), i = parseFloat(inch);
  if (!Number.isFinite(f) && !Number.isFinite(i)) { delete canon.height; values.height = ""; }
  else {
    const total = (Number.isFinite(f) ? f : 0) * 12 + (Number.isFinite(i) ? i : 0);
    canon.height = total * 2.54;
    values.height = fmtNum(total);
  }
  return { ...form, values, canon };
}

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
const isNum = (t) => t === "length" || t === "weight" || t === "shoe" || t === "height";
const fieldFor = (k, fit) => ALL_FIELDS.find((f) => f.k === k && applicable(f, fit));
const displayStr = (t, canonV, units, scale, fit) =>
  t === "shoe" ? fmtNum(shoeFromUS(canonV, fit)[scale]) : fmtNum(toDisplay(t, canonV, units));

// Form state: `values` are display strings, `canon` holds exact canonical numbers (cm/kg/US) for numeric fields.
export function toForm(doc, units) {
  let values = {};
  const canon = {};
  const fit = doc?.fit || null;
  const shoeScale = units === "metric" ? "EU" : "US";
  for (const [k, v] of Object.entries(doc?.values || {})) {
    const t = typeOf(k);
    if (isNum(t)) { canon[k] = v; values[k] = displayStr(t, v, units, shoeScale, fit); }
    else values[k] = String(v);
  }
  if (units !== "metric") values = withHeightParts(values, canon);
  return { fit, values, canon, shoeScale };
}

export function setNumeric(form, k, raw, units) {
  const t = typeOf(k);
  const n = parseFloat(raw);
  const canon = { ...form.canon };
  if (Number.isFinite(n)) canon[k] = t === "shoe" ? shoeToUS(n, form.shoeScale, form.fit) : toCanonical(t, n, units);
  else delete canon[k];
  return { ...form, values: { ...form.values, [k]: raw }, canon };
}

export function fromForm(form) {
  const out = {};
  for (const [k, raw] of Object.entries(form.values || {})) {
    if (raw === "" || raw == null) continue;
    const f = fieldFor(k, form.fit);
    if (!f) continue;
    if (isNum(f.type)) { if (Number.isFinite(form.canon?.[k])) out[k] = form.canon[k]; }
    else out[k] = raw;
  }
  return out;
}

export function convertForm(form, fromUnits, toUnits) {
  if (fromUnits === toUnits) return form;
  let values = { ...form.values };
  for (const [k, c] of Object.entries(form.canon || {})) {
    const t = typeOf(k);
    if (t === "length" || t === "weight" || t === "height") values[k] = fmtNum(toDisplay(t, c, toUnits));
  }
  if (toUnits !== "metric") values = withHeightParts(values, form.canon || {});
  return { ...form, values };
}

export function changeShoeScale(form, scale) {
  const values = { ...form.values };
  if (Number.isFinite(form.canon?.shoe_us)) values.shoe_us = fmtNum(shoeFromUS(form.canon.shoe_us, form.fit)[scale]);
  return { ...form, values, shoeScale: scale };
}

export function changeFit(form, fit) {
  const canon = { ...form.canon };
  const n = parseFloat(form.values.shoe_us);
  if (Number.isFinite(n)) canon.shoe_us = shoeToUS(n, form.shoeScale, fit);
  return { ...form, fit, canon };
}

export function completion(section, form) {
  const fields = sectionFields(section, form.fit);
  const filled = fields.filter((f) => (form.values[f.k] ?? "") !== "").length;
  return { filled, total: fields.length };
}

export const isStale = (iso) => !!iso && Date.now() - new Date(iso).getTime() > 365 * 86400000;
