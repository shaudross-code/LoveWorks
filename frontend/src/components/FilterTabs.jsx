import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";

// tabs: [{ value, label, count? }]; each trigger gets data-testid `${testPrefix}${value}`.
export default function FilterTabs({ tabs, value, onChange, testPrefix }) {
  return (
    <Tabs value={value} onValueChange={onChange}>
      <TabsList className="bg-[#121214] border border-yellow-400/15 rounded-xl p-1 h-auto flex-wrap justify-start max-w-full">
        {tabs.map((t) => (
          <TabsTrigger key={t.value} value={t.value} data-testid={`${testPrefix}${t.value}`}
            className="rounded-lg data-[state=active]:bg-yellow-400 data-[state=active]:text-black capitalize">
            {t.label}
            {t.count != null && <span className="ml-1.5 text-xs opacity-60">{t.count}</span>}
          </TabsTrigger>
        ))}
      </TabsList>
    </Tabs>
  );
}
