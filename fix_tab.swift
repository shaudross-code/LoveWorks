import Foundation

let path = "iLoveWorks/WorkerDashboardView.swift"
let content = try! String(contentsOfFile: path)
let lines = content.components(separatedBy: "\n")
var result: [String] = []
var skip = false
for line in lines {
    if line.contains("ProfileView(workerViewModel") {
        skip = true
    } else if skip, line.contains(".tabItem") {
        skip = false
    } else {
        result.append(line)
    }
}
try! result.joined(separator: "\n").write(toFile: path, atomically: true, encoding: .utf8)
