import re

with open("iLoveWorks/AdminViewModel.swift", "r") as f:
    text = f.read()

# I will add update methods after createTask
create_task_method = """    func createTask(_ req: TaskCreateRequest) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks", method: "POST", json: req)
        await refreshDashboard()
    }"""

update_methods = """    func createTask(_ req: TaskCreateRequest) async throws {
        let _: TaskItem = try await APIClient.shared.send("/tasks", method: "POST", json: req)
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

text = text.replace(create_task_method, update_methods)

with open("iLoveWorks/AdminViewModel.swift", "w") as f:
    f.write(text)
print("Patched AdminViewModel")
