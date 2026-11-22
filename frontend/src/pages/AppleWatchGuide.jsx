import { Watch, Smartphone, HeartPulse, Radio, Share2, Scale, LifeBuoy, Bluetooth, ShieldCheck } from "lucide-react";

const STEPS = [
  {
    icon: Bluetooth, title: "1. Check your iPhone and Watch are paired",
    items: [
      "Your Apple Watch must already be paired with the iPhone that has iLoveWorks (iPhone Watch app → My Watch).",
      "Keep Bluetooth and Wi-Fi on. The Watch sends its numbers to your iPhone over Bluetooth when they're close, the quickest link, and switches to Wi-Fi by itself when they're further apart. There's nothing to choose in iLoveWorks.",
    ],
  },
  {
    icon: Watch, title: "2. Put iLoveWorks on your Watch",
    items: [
      "Install or update iLoveWorks on your iPhone first.",
      "On the iPhone, open the Watch app → My Watch → scroll to Available Apps → tap Install next to iLoveWorks. (If it already shows under Installed on Apple Watch, you're set.)",
      "Find the iLoveWorks icon on your Watch's app list.",
    ],
  },
  {
    icon: HeartPulse, title: "3. Let iLoveWorks read Apple Health on your iPhone",
    items: [
      "In the iLoveWorks iPhone app tap Profile → Apple Watch, Scale & Health → Connect Apple Health.",
      "Turn on Active Energy, Resting Energy, Weight, Body Fat Percentage and Body Mass Index → Allow.",
      "Changed your mind later? iPhone Settings → Health → Data Access & Devices → iLoveWorks.",
    ],
  },
  {
    icon: Watch, title: "4. Allow Health on the Watch",
    items: [
      "Open iLoveWorks on the Watch. The first time, tap Allow Health access and turn the switches on.",
      "The Watch now shows today's Active and Total calories.",
    ],
  },
  {
    icon: Radio, title: "5. Record live",
    items: [
      "On the Watch tap Start live. Active calories update every few seconds over Bluetooth and your iPhone shows \u201clive from Apple Watch\u201d.",
      "Tap Stop live when you're done. It's saved in the Fitness app as an \u201cOther\u201d workout and counts toward your Move ring.",
      "No live session running? You still get all-day totals: the iPhone reads them from Apple Health every time you open iLoveWorks, and in the background about once an hour.",
    ],
  },
  {
    icon: Scale, title: "6. Weigh in with your VeSync scale over Bluetooth",
    items: [
      "Works with these Etekcity (VeSync) scales: ESF-551, ESF-24, ESF-17, ESF-18 and FIT-8S. The model is printed on the back of the scale.",
      "Close the VeSync app first. A scale only talks to one app at a time.",
      "In the iPhone app go to Profile → Apple Watch, Scale & Health → Weigh in with Bluetooth. The first time, iPhone asks to allow Bluetooth. Tap Allow.",
      "Step on the scale and hold still. iLoveWorks finds it, reads your weight and shows it to you.",
      "Tap Save weigh-in to keep it, or Discard if it's wrong. Nothing is saved until you tap Save. You can also save it to Apple Health with the switch on that screen.",
      "iLoveWorks remembers your scale so it won't pick up anyone else's. Tap Forget on the scale card to pair a different one.",
    ],
  },
  {
    icon: Scale, title: "7. Other VeSync scales: connect through Apple Health",
    items: [
      "Newer VeSync scales (for example EFS-A591S and EFS-C651) lock their Bluetooth data, so iLoveWorks can't read them directly. iLoveWorks tells you if yours is one of these.",
      "In the VeSync app: Me (profile) → Third-party services (sometimes called Integrations) → Apple Health → Connect. Allow Weight, Body Fat Percentage and BMI. The menu names can differ slightly by VeSync version.",
      "Weigh in with the VeSync app open nearby. The reading goes to Apple Health, then shows up in iLoveWorks the next time it refreshes.",
    ],
  },
  {
    icon: Share2, title: "8. Share with your admin (optional)",
    items: [
      "On your dashboard (web or iPhone) turn on \u201cShare my calories and weight with my admin\u201d.",
      "Your admin then sees your latest active and total calories and weight on their Workers tab. Turn it off any time.",
    ],
  },
  {
    icon: ShieldCheck, title: "Your permissions",
    items: [
      "Bluetooth: only used when you tap Weigh in. Turn it off any time in iPhone Settings → iLoveWorks → Bluetooth.",
      "Apple Health: you choose each type of data. iPhone Settings → Health → Data Access & Devices → iLoveWorks.",
      "Admin sharing is off until you turn it on.",
    ],
  },
  {
    icon: LifeBuoy, title: "If something doesn't show",
    items: [
      "No iLoveWorks on the Watch: iPhone Watch app → Available Apps → Install. Restart both devices if it's stuck.",
      "Calories show 0 or \u201cno numbers yet\u201d: check iPhone Settings → Health → Data Access & Devices → iLoveWorks; every switch should be on.",
      "Live numbers not moving on the iPhone: keep the phone nearby with Bluetooth on and iLoveWorks open.",
      "Scale not found: close the VeSync app (swipe it away), keep the phone within a few feet, step on the scale again and tap Try again.",
      "\u201cBluetooth isn't allowed\u201d: iPhone Settings → iLoveWorks → turn on Bluetooth.",
      "Weight missing with the Apple Health route: open VeSync once after weighing so it pushes the reading to Apple Health.",
      "The website can't use Bluetooth or read Apple Health. Only the iPhone app can; the website shows what the iPhone sent.",
    ],
  },
];

export default function AppleWatchGuide() {
  return (
    <div data-testid="apple-watch-guide" className="max-w-3xl">
      <div className="text-xs uppercase tracking-[0.3em] text-pink-400">Setup guide</div>
      <h1 className="font-display text-4xl sm:text-5xl font-semibold mt-2">Connect your Apple Watch &amp; scale</h1>
      <p className="mt-3 text-zinc-400 flex items-center gap-2"><Smartphone className="w-4 h-4" /> Takes about 3 minutes. You need the iLoveWorks iPhone app, plus a paired Apple Watch and/or a VeSync smart scale.</p>
      <div className="mt-8 space-y-4">
        {STEPS.map(({ icon: Icon, title, items }, i) => (
          <section key={title} data-testid={`guide-step-${i + 1}`} className="rounded-2xl border border-white/5 bg-[#121214] p-5"
            style={{ animation: `fadeUp .4s ease ${i * 60}ms both` }}>
            <h2 className="font-display font-semibold text-base md:text-lg flex items-center gap-2"><Icon className="w-5 h-5 text-yellow-400" /> {title}</h2>
            <ul className="mt-3 space-y-2 text-sm text-zinc-300 list-disc list-inside marker:text-zinc-600">
              {items.map((t) => <li key={t}>{t}</li>)}
            </ul>
          </section>
        ))}
      </div>
    </div>
  );
}
