//
//  Logger.swift
//  TrackBoth
//
//  Created by Jacob Rozell on 12/19/24.
//

import Foundation
import os.log

// MARK: - Log Levels
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
    case fatal = "FATAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warn:
            return .default
        case .error:
            return .error
        case .fatal:
            return .fault
        }
    }
}

// MARK: - Log Categories
enum LogCategory: String, CaseIterable {
    case ui = "UI"
    case data = "DATA"
    case business = "BUSINESS"
    case performance = "PERFORMANCE"
    case general = "GENERAL"
}

// MARK: - Logger
class Logger {
    static let shared = Logger()
    
    private let subsystem = "com.jacobrozell.TrackBoth"
    private var loggers: [LogCategory: OSLog] = [:]
    
    private init() {
        // Initialize OSLog instances for each category
        for category in LogCategory.allCases {
            loggers[category] = OSLog(subsystem: subsystem, category: category.rawValue)
        }
    }
    
    // MARK: - Public Logging Methods
    
    func debug(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, category: category, file: file, function: function, line: line)
    }
    
    func warn(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warn, message: message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, category: category, file: file, function: function, line: line)
    }
    
    func fatal(_ message: String, category: LogCategory = .general, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .fatal, message: message, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private func log(level: LogLevel, message: String, category: LogCategory, file: String, function: String, line: Int) {
        #if DEBUG
        // In debug builds, always log
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(level.rawValue)] [\(category.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        print(logMessage)
        #endif
        
        // Use OSLog for system integration
        guard let logger = loggers[category] else { return }
        os_log("%{public}@", log: logger, type: level.osLogType, message)
    }
    
    // MARK: - Convenience Methods
    
    func logUserAction(_ action: String, details: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let message = details != nil ? "\(action): \(details!)" : action
        info(message, category: .ui, file: file, function: function, line: line)
    }
    
    func logDataOperation(_ operation: String, entity: String, success: Bool, file: String = #file, function: String = #function, line: Int = #line) {
        let status = success ? "SUCCESS" : "FAILED"
        let message = "\(operation) \(entity) - \(status)"
        let level: LogLevel = success ? .info : .error
        log(level: level, message: message, category: .data, file: file, function: function, line: line)
    }
    
    func logPerformance(_ operation: String, duration: TimeInterval, file: String = #file, function: String = #function, line: Int = #line) {
        let message = "\(operation) completed in \(String(format: "%.3f", duration))s"
        info(message, category: .performance, file: file, function: function, line: line)
    }
    
    func logError(_ error: Error, context: String, file: String = #file, function: String = #function, line: Int = #line) {
        let message = "\(context): \(error.localizedDescription)"
        self.error(message, category: .general, file: file, function: function, line: line)
    }
}

// MARK: - Global Logger Instance
let logger = Logger.shared
