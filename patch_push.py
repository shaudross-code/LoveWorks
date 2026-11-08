import re

with open("iLoveWorks/PushManager.swift", "r") as f:
    text = f.read()

old = """        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \\(error)")
        }"""

new = """        Task {
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                AVAudioSession.sharedInstance().activate(options: []) { success, error in
                    if let error = error {
                        print("Failed to configure audio session asynchronously: \\(error)")
                    }
                }
            } catch {
                print("Failed to set audio session category: \\(error)")
            }
        }"""
text = text.replace(old, new)


with open("iLoveWorks/PushManager.swift", "w") as f:
    f.write(text)
