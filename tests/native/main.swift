import Foundation

let dir = "/tmp/api/"
let dec: JSONDecoder = { let d = JSONDecoder(); d.keyDecodingStrategy = .convertFromSnakeCase; return d }()
var failures = 0

func check<T: Decodable>(_ type: T.Type, _ file: String) -> T? {
    do {
        let data = try Data(contentsOf: URL(fileURLWithPath: dir + file))
        let v = try dec.decode(T.self, from: data)
        print("OK  \(file) -> \(T.self)")
        return v
    } catch {
        failures += 1
        print("FAIL \(file) -> \(T.self): \(error)")
        return nil
    }
}
func expect(_ cond: Bool, _ msg: String) { if cond { print("OK  \(msg)") } else { failures += 1; print("FAIL \(msg)") } }

_ = check(LoginResponse.self, "login_admin.json")
_ = check(LoginResponse.self, "login_worker.json")
_ = check(User.self, "admin_auth_me.json")
_ = check([User].self, "admin_workers.json")
let adminTasks = check([TaskItem].self, "admin_tasks.json")
_ = check([TaskItem].self, "worker_tasks.json")
_ = check([PayrollRow].self, "admin_payroll.json")
_ = check([WorkerStatus].self, "admin_admin_worker-status.json")
_ = check([Goal].self, "admin_goals_kind_goal.json")
_ = check([Goal].self, "admin_goals_kind_trip.json")
_ = check([Goal].self, "worker_goals_kind_goal.json")
_ = check([Goal].self, "worker_goals_kind_trip.json")
_ = check([Essential].self, "admin_essentials.json")
_ = check([Essential].self, "worker_essentials.json")
_ = check([Announcement].self, "admin_announcements.json")
_ = check([Announcement].self, "worker_announcements.json")
let entries = check([TimeEntry].self, "worker_time_entries.json")
_ = check([TimeEntry].self, "worker_time_active.json")
_ = check(NotificationsResponse.self, "worker_notifications.json")
_ = check(WeeklyActivityResponse.self, "worker_me_weekly-activity.json")
_ = check(AwardResponse.self, "worker_awards.json")
let wsizes = check(SizesDoc.self, "worker_sizes_me.json")
_ = check(SizesDoc.self, "admin_sizes_me.json")
let theme = check(ThemeState.self, "admin_theme.json")
for f in ["sizes_empty.json", "sizes_put.json", "worker_sizes_admin.json", "react.json"] {
    if FileManager.default.fileExists(atPath: dir + f) {
        switch f {
        case "sizes_empty.json": _ = check(SizesDoc.self, f)
        case "react.json": _ = check(Goal.self, f)
        case "worker_sizes_admin.json": _ = check(WorkerSizesResponse.self, f)
        default: _ = check(SizesSaveResponse.self, f)
        }
    }
}

// Dates
expect(APIDate.parse("2026-11-01T18:14:00.174231+00:00") != nil, "parse microseconds")
expect(APIDate.parse("2026-06-05T00:00:00+00:00") != nil, "parse no fraction")
expect(APIDate.parse("2026-06-05") != nil, "parse day only")
expect(APIDate.parse("2026-06-05T10:00:00") != nil, "parse naive")
if let e = entries?.first { expect(APIDate.parse(e.clockIn) != nil, "entry clockIn parses") }

// Sizes round trip
if let doc = wsizes {
    var f = SizesForm(doc: doc, units: .imperial)
    expect(f.value("height_ft") == "5" && f.value("height_in") == "10", "height 177.8cm -> 5 ft 10 in (got \(f.value("height_ft")) ft \(f.value("height_in")) in)")
    expect(f.value("weight") == "175", "weight 79.38kg -> 175 lb (got \(f.value("weight")))")
    expect(f.value("shoe_us") == "10.5", "shoe 10.5 US")
    f.convert(from: .imperial, to: .metric)
    expect(f.value("height") == "177.8", "metric height 177.8 (got \(f.value("height")))")
    f.convert(from: .metric, to: .imperial)
    expect(f.value("weight") == "175", "weight back to 175 lb")
    f.setHeightImperial(ft: "6", inch: "1")
    expect(abs((f.canon["height"] ?? 0) - 185.42) < 0.01, "6 ft 1 in -> 185.42 cm")
    f.changeShoeScale(.EU)
    expect(f.value("shoe_us") == "43.5", "10.5 US men -> EU 43.5 (got \(f.value("shoe_us")))")
    f.setNumeric("shoe_us", "44", units: .imperial)
    expect(f.canon["shoe_us"] == 11, "EU 44 -> US 11")
    f.setText("casual_top", "M")
    f.setText("dress", "8")
    let p = f.payload()
    expect(p["casual_top"] == .string("M"), "casual_top in payload")
    expect(p["dress"] == nil, "dress (womens only) excluded for mens")
    expect(p["height_ft"] == nil && p["height_in"] == nil, "ft/in helper keys never sent")
    let casual = SizesConstants.SECTIONS.first { $0.key == "casual" }!
    expect(f.completion(casual).total == 6, "casual has 6 fields for mens")
    let order = SizesConstants.SECTIONS.map(\.key)
    expect(order == ["body", "footwear", "casual", "workout", "workwear", "underclothes", "notes"], "section order \(order)")
}

// Task buckets
var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "UTC")!
let wed = cal.date(from: DateComponents(year: 2026, month: 11, day: 4, hour: 12))! // Wednesday
func task(_ id: String, dow: Int?, dueAt: String? = nil, time: String? = nil) -> TaskItem {
    TaskItem(id: id, title: id, description: nil, price: 10, status: "assigned", assigneeId: "a", assigneeName: nil, frequency: "weekly", payoutSchedule: nil, dueAt: dueAt, dueTime: time, dueDayOfWeek: dow, estimatedHours: nil, dailyHours: nil, completedAt: nil)
}
let b = TaskSchedule.buckets([task("wed", dow: 2), task("fri", dow: 4), task("mon", dow: 0), task("past", dow: nil, dueAt: "2026-11-01T00:00:00+00:00"), task("none", dow: nil)], now: wed, calendar: cal)
expect(b.dueToday.map(\.id) == ["wed"], "dow today -> Due today")
expect(b.dueThisWeek.map(\.id) == ["fri"], "dow later this week -> This week")
expect(b.later.map(\.id).sorted() == ["mon", "none"], "next Monday / no date -> later")
expect(b.overdue.map(\.id) == ["past"], "past due_at -> overdue")
expect(b.weeklyPotential == 20, "weekly potential counts wed+fri (got \(b.weeklyPotential))")
expect(TaskSchedule.dueLabel(task("x", dow: 4, time: "18:00")) == "Fri · by 18:00", "due label")
if let t = adminTasks { _ = TaskSchedule.buckets(t) ; print("OK  buckets on real tasks") }

// Theme
if let s = theme {
    expect(ThemeCache.effectiveKey(s, today: cal.date(from: DateComponents(year: 2026, month: 11, day: 4))!) == "halloween", "halloween active Nov 4")
    expect(ThemeCache.effectiveKey(s, today: cal.date(from: DateComponents(year: 2026, month: 11, day: 9))!) == "default", "cached halloween expires after Nov 7")
    expect(ThemePalette.forKey("halloween").accent == "#A78BFA", "halloween accent purple")
    let d = UserDefaults(suiteName: "t")!
    ThemeCache.save(s, d)
    expect(ThemeCache.load(d) == s, "cache round trip")
}
expect(SizeHelper.fmtNum(5.0) == "5" && SizeHelper.fmtNum(10.55) == "10.6", "fmtNum")
expect(MeasureGuide.items.count == 10, "guide items")

print(failures == 0 ? "ALL PASSED" : "FAILURES: \(failures)")
exit(failures == 0 ? 0 : 1)
