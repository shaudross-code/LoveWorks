import re

with open("iLoveWorks/WorkerDashboardView.swift", "r") as f:
    text = f.read()

# 1. Add `case goals = "Goals"` after `history` in `WorkerTab`
text = re.sub(
    r"case history = \"History\"",
    r"case history = \"History\"\n    case goals = \"Goals\"",
    text
)

# 2. Add `case .goals: return "target"` to `icon` property of `WorkerTab`
text = re.sub(
    r"case \.history: return \"clock\.arrow\.circlepath\"",
    r"case .history: return \"clock.arrow.circlepath\"\n        case .goals: return \"target\"",
    text
)

# 3. Add `case .goals: WorkerGoalsView(viewModel: viewModel)` in the `Group { switch selectedTab }` of `WorkerDashboardView`
text = re.sub(
    r"case \.history:\n                        WorkerHistoryView\(viewModel: viewModel\)",
    r"case .history:\n                        WorkerHistoryView(viewModel: viewModel)\n                    case .goals:\n                        WorkerGoalsView(viewModel: viewModel)",
    text
)

# 4. We need to create `WorkerGoalsView`. We can append it to the end of the file.
worker_goals_view = """
struct WorkerGoalsView: View {
    @ObservedObject var viewModel: WorkerViewModel

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    PageHeader(eyebrow: "WISHLIST", title: "Target Goals.")

                    VStack(spacing: 12) {
                        if viewModel.goals.isEmpty {
                            Text("No active goals found.")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textMuted)
                                .padding()
                        } else {
                            ForEach(viewModel.goals) { goal in
                                GoalCard(goal: goal, onReactionsChange: { newReactions in
                                    viewModel.setReactions(goalId: goal.id, newReactions)
                                })
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
        }
    }
}
"""

text += "\n" + worker_goals_view

with open("iLoveWorks/WorkerDashboardView.swift", "w") as f:
    f.write(text)
    
print("Added WorkerGoalsView!")
