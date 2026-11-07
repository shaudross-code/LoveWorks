import re

with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()

# Add frequency & payoutSchedule to TaskUpdateRequest
old_task_req = """    struct TaskUpdateRequest: Encodable {
        let title: String?
        let description: String?
        let price: Double?
        let assigneeId: String?
        let frequency: String?
        let adminAlarm: String?
    }"""
new_task_req = """    struct TaskUpdateRequest: Encodable {
        let title: String?
        let description: String?
        let price: Double?
        let assigneeId: String?
        let frequency: String?
        let payoutSchedule: String?
        let adminAlarm: String?
    }"""
if old_task_req in text:
    text = text.replace(old_task_req, new_task_req)
else:
    print("WARNING: TaskUpdateRequest not found exactly")

# Add ownerId, imageUrl, productLink to GoalUpdateRequest
old_goal_req = """    struct GoalUpdateRequest: Encodable {
        let title: String?
        let targetAmount: Double?
        let period: String?
    }"""
new_goal_req = """    struct GoalUpdateRequest: Encodable {
        let title: String?
        let targetAmount: Double?
        let period: String?
        let ownerId: String?
        let productLink: String?
        let imageUrl: String?
    }"""
if old_goal_req in text:
    text = text.replace(old_goal_req, new_goal_req)

# Add WorkerUpdateRequest + updateWorker
worker_methods = """    struct WorkerUpdateRequest: Encodable {
        let name: String?
        let email: String?
    }

    func updateWorker(workerId: String, req: WorkerUpdateRequest) async throws {
        let _: User = try await APIClient.shared.send("/workers/\\(workerId)", method: "PATCH", json: req)
        await refreshDashboard()
    }

    func deleteWorker"""

if "WorkerUpdateRequest" not in text:
    text = text.replace("    func deleteWorker", worker_methods)

with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)
print("Patched AdminViewModel.swift successfully.")
