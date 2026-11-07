import Foundation

let path = "iLoveWorks/iLoveWorksApp.swift"
let content = try! String(contentsOfFile: path)
let lines = content.components(separatedBy: "\n")
var result: [String] = []
var inAppDelegate = false
for line in lines {
    if line.hasPrefix("class AppDelegate:") {
        inAppDelegate = true
    } else if inAppDelegate, line == "}" {
        inAppDelegate = false
    } else if !inAppDelegate {
        result.append(line)
    }
}
// wait, the #if canImport(UIKit) block was around AppDelegate. I should remove that too.
