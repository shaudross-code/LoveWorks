//
//  ClockInAttributes.swift
//  Shared by the iLoveWorks app and its widget extension (lock-screen clock-in timer).
//  The server starts/updates/ends this timer by push, so property names must match
//  the JSON it sends: entryId, workerName, startedAt / onBreak, activityLabel.
//

#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation

nonisolated struct ClockInAttributes: ActivityAttributes {
    nonisolated struct ContentState: Codable, Hashable {
        var onBreak: Bool
        var activityLabel: String
    }

    var entryId: String
    var workerName: String
    /// Clock-in time, Unix seconds.
    var startedAt: Double

    var startDate: Date { Date(timeIntervalSince1970: startedAt) }
}
#endif
