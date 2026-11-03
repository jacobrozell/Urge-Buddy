#!/usr/bin/env swift
// Press Device Hub pose / rotate buttons via Accessibility.
// Usage: devicehub-pose.swift closed|book|open|rotate

import AppKit
import ApplicationServices
import Foundation

let want = CommandLine.arguments.dropFirst().first?.lowercased() ?? ""
let labels: [String: String] = [
    "closed": "Closed",
    "book": "Book",
    "open": "Open",
    "rotate": "Rotate Right",
]
guard let target = labels[want] else {
    fputs("Usage: devicehub-pose.swift closed|book|open|rotate\n", stderr)
    exit(2)
}

func attr(_ el: AXUIElement, _ name: String) -> AnyObject? {
    var value: AnyObject?
    AXUIElementCopyAttributeValue(el, name as CFString, &value)
    return value
}

func findButton(in root: AXUIElement, description: String) -> AXUIElement? {
    var queue: [AXUIElement] = [root]
    var seen = Set<UInt>()
    var index = 0
    while index < queue.count, index < 8_000 {
        let el = queue[index]
        index += 1
        let key = UInt(bitPattern: Unmanaged.passUnretained(el).toOpaque())
        if !seen.insert(key).inserted { continue }
        let role = attr(el, kAXRoleAttribute) as? String ?? ""
        let desc = attr(el, kAXDescriptionAttribute) as? String ?? ""
        if role == "AXButton", desc == description { return el }
        if role == "AXMenuBar" || role == "AXMenu" || role == "AXMenuBarItem" { continue }
        if let kids = attr(el, kAXChildrenAttribute) as? [AXUIElement] {
            queue.append(contentsOf: kids)
        }
    }
    return nil
}

func deviceHubPID() -> pid_t? {
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dt.Devices")
    if let app = running.first, app.processIdentifier > 0 {
        return app.processIdentifier
    }
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    task.arguments = ["-f", "DeviceHub.app/Contents/MacOS/DeviceHub"]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    try? task.run()
    task.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else { return nil }
    for line in text.split(separator: "\n") {
        if let pid = pid_t(line.trimmingCharacters(in: .whitespaces)) {
            return pid
        }
    }
    return nil
}

NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Applications/DeviceHub.app"))
Thread.sleep(forTimeInterval: 0.8)

guard let pid = deviceHubPID() else {
    fputs("Device Hub is not running.\n", stderr)
    exit(1)
}

// Device Hub hides its device window from Accessibility until it is the front app.
// NSRunningApplication.activate is ignored for this process, so ask System Events.
let activate = Process()
activate.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
activate.arguments = ["-e", "tell application \"DeviceHub\" to activate"]
activate.standardOutput = FileHandle.nullDevice
activate.standardError = FileHandle.nullDevice
try? activate.run()
activate.waitUntilExit()
Thread.sleep(forTimeInterval: 0.6)

let axApp = AXUIElementCreateApplication(pid)
guard let windows = attr(axApp, kAXWindowsAttribute) as? [AXUIElement] else {
    fputs("No Device Hub windows.\n", stderr)
    exit(1)
}

for window in windows {
    if let button = findButton(in: window, description: target) {
        let err = AXUIElementPerformAction(button, kAXPressAction as CFString)
        if err != .success {
            fputs("Could not press \(target) (AX error \(err.rawValue)).\n", stderr)
            exit(1)
        }
        print("Pressed \(target)")
        exit(0)
    }
}

fputs("No \(target) button in Device Hub.\n", stderr)
exit(1)
