import re

with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()

# I will add update methods after createWorker
create_worker_method = """    func createWorker(name: String, email: String, password: String) async throws {
        let _: User = try await APIClient.shared.send("/workers", json: ["name": name, "email": email, "password": password])
        await refreshDashboard()
    }"""

update_methods = """    func createWorker(name: String, email: String, password: String) async throws {
        let _: User = try await APIClient.shared.send("/workers", json: ["name": name, "email": email, "password": password])
        await refreshDashboard()
    }
    
    struct TaskUpdateRequest: Encodable {
        let title: String?
        let description: String?
        let price: Double?
        let assigneeId: String?
        let frequency: String?
        let adminAlarm: String?
    }
    
    func updateTask(taskId: String, req: TaskUpdateRequest) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks/\\(taskId)", method: "PATCH", json: req)
        await refreshDashboard()
    }
    
    struct GoalUpdateRequest: Encodable {
        let title: String?
        let targetAmount: Double?
        let period: String?
    }
    
    func updateGoal(goalId: String, req: GoalUpdateRequest) async throws {
        let _: Goal = try await APIClient.shared.send("/goals/\\(goalId)", method: "PATCH", json: req)
        // Also refresh goals/trips as they use the same endpoint
        loadGoals()
        loadTrips()
    }
    
    func deleteGoal(goalId: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request("/goals/\\(goalId)", method: "DELETE")
        loadGoals()
        loadTrips()
    }
    
    func deleteTask(taskId: String) async throws {
        let _: EmptyResponse = try await APIClient.shared.request("/tasks/\\(taskId)", method: "DELETE")
        await refreshDashboard()
    }
"""

if create_worker_method not in text:
    raise Exception("Match failed")

text = text.replace(create_worker_method, update_methods)

with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)
print("Patched AdminViewModel accurately!")
