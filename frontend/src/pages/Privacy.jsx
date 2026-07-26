import { Heart, ShieldCheck, ArrowLeft } from "lucide-react";
import { Link } from "react-router-dom";

const SECTIONS = [
  {
    title: "1. Who we are",
    body: "iLoveWorks is a household task and love-tracking app. An administrator (usually a family member or partner) creates accounts for workers, assigns tasks with rewards, and celebrates achievements. This policy explains what data the app stores and how it is used.",
  },
  {
    title: "2. Information we collect",
    body: "Account data: your email address, display name, and a securely hashed password (we never store your password in plain text). Content you create: tasks, time entries (clock-in/clock-out activity), goals, trips, essentials lists, announcements, reactions, and any photos you upload (profile pictures, goal/trip/essential images). Usage data: timestamps of your activity in the app (used for presence indicators, streaks, and idle alerts).",
  },
  {
    title: "3. How we use your information",
    body: "Your data is used solely to provide app functionality: displaying tasks and earnings, tracking time and streaks, computing goal progress, sending in-app and push notifications (task reminders, assignments, celebrations), and letting your admin oversee household activity. We do not sell your data, show ads, or share your information with third parties for marketing.",
  },
  {
    title: "4. Push notifications",
    body: "If you opt in, we store a push subscription for your browser or device so we can send reminders (for example, 30 minutes before a task is due) and activity alerts. You can turn push notifications off at any time from your Profile page, and the subscription is removed.",
  },
  {
    title: "5. Where your data is stored",
    body: "Account and activity data is stored in a MongoDB database. Uploaded images are stored in secure object storage and are only accessible to authenticated members of your household workspace. Data is encrypted in transit (HTTPS).",
  },
  {
    title: "6. Data retention & account deletion",
    body: "Your data is kept while your account is active. You can permanently delete your account at any time from Profile → Danger zone → \"Delete my account\". This removes your profile, tasks, time entries, goals, trips, essentials, awards, notifications, and push subscriptions, and marks your uploaded images for deletion. This action cannot be undone. Admins may also remove worker accounts, which deletes the worker's tasks and time entries.",
  },
  {
    title: "7. Children",
    body: "Accounts are created only by the household administrator. The app is intended for use within a family or small team under the supervision of the administrator.",
  },
  {
    title: "8. Changes to this policy",
    body: "If this policy changes, the updated version will be posted on this page with a new effective date.",
  },
  {
    title: "9. Contact",
    body: "For any privacy questions or data requests, contact your household administrator (the person who invited you), who manages the workspace and its data.",
  },
];

export default function Privacy() {
  return (
    <div className="min-h-screen bg-[#09090B] text-white">
      <div className="max-w-3xl mx-auto px-6 py-12 sm:py-16">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-pink-400 to-rose-500 grid place-items-center shadow-lg shadow-pink-500/30">
            <Heart className="w-5 h-5 text-white fill-white" />
          </div>
          <div>
            <div className="font-display text-xl font-bold leading-none brand-gold">iLoveWorks</div>
            <div className="text-[10px] text-zinc-500 mt-1 uppercase tracking-widest">Love · Tasks · Gifts</div>
          </div>
        </div>

        <h1 className="font-display text-4xl sm:text-5xl font-bold tracking-tight mt-10" data-testid="privacy-title">
          Privacy Policy
        </h1>
        <p className="mt-3 text-sm text-zinc-500 inline-flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-pink-400" /> Effective date: June 2026
        </p>

        <div className="mt-10 space-y-8">
          {SECTIONS.map((s) => (
            <section key={s.title}>
              <h2 className="font-display text-lg font-semibold text-yellow-400">{s.title}</h2>
              <p className="mt-2 text-zinc-300 leading-relaxed text-sm sm:text-base">{s.body}</p>
            </section>
          ))}
        </div>

        <div className="mt-12 pt-8 border-t border-yellow-400/10 flex items-center justify-between flex-wrap gap-3">
          <Link to="/login" data-testid="privacy-back-link"
            className="inline-flex items-center gap-2 text-sm text-zinc-400 hover:text-yellow-400 transition">
            <ArrowLeft className="w-4 h-4" /> Back to sign in
          </Link>
          <div className="text-xs text-zinc-600">© iLoveWorks — built with love &amp; gold.</div>
        </div>
      </div>
    </div>
  );
}
