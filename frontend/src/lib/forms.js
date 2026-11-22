// Props for a controlled field bound to form[key]: <LabeledInput {...field("title")} />
export const bindField = (form, setForm) => (key) => ({
  value: form[key],
  onValue: (v) => setForm((f) => ({ ...f, [key]: v })),
});
