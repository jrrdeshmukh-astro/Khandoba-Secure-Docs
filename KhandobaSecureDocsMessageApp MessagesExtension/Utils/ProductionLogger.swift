//
//  ProductionLogger.swift
//  Khandoba Secure Docs
//
//  Production logging utility for iMessage extension
//

import Foundation
import os.log

enum LogLevel: String {
    case debug = "🔍 DEBUG"
    case info = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error = "❌ ERROR"
    case success = "✅ SUCCESS"
    case critical = "🚨 CRITICAL"
}

final class ProductionLogger {
    static let shared = ProductionLogger()
    
    private let subsystem = "com.khandoba.securedocs.messages"
    private let category = "iMessageExtension"
    private let logger: Logger
    
    private init() {
        logger = Logger(subsystem: subsystem, category: category)
    }
    
    // MARK: - Public Logging Methods
    
    func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(level.rawValue)] [\(fileName):\(line)] \(function) - \(message)"
        
        // Console output
        print(logMessage)
        
        // OS Log (for system logs and Console.app)
        switch level {
        case .debug:
            logger.debug("\(logMessage)")
        case .info:
            logger.info("\(logMessage)")
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        case .success:
            logger.info("\(logMessage)")
        case .critical:
            logger.critical("\(logMessage)")
        }
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
            if let nsError = error as NSError? {
                fullMessage += " | Domain: \(nsError.domain) | Code: \(nsError.code)"
            }
        }
        log(.error, fullMessage, file: file, function: function, line: line)
    }
    
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.success, message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error.localizedDescription)"
        }
        log(.critical, fullMessage, file: file, function: function, line: line)
    }
    
    // MARK: - Flow-Specific Logging
    
    func logNomineeInvitation(vaultName: String, recipientName: String, token: String) {
        info("Nominee Invitation | Vault: \(vaultName) | Recipient: \(recipientName) | Token: \(token)")
    }
    
    func logNomineeAcceptance(token: String, vaultName: String) {
        info("Nominee Acceptance | Token: \(token) | Vault: \(vaultName)")
    }
    
    func logTransferRequest(vaultName: String, recipientName: String, token: String) {
        info("Transfer Request | Vault: \(vaultName) | New Owner: \(recipientName) | Token: \(token)")
    }
    
    func logTransferAcceptance(token: String, vaultName: String) {
        info("Transfer Acceptance | Token: \(token) | Vault: \(vaultName)")
    }
    
    func logEmergencyRequest(vaultName: String, urgency: String, reason: String) {
        warning("Emergency Request | Vault: \(vaultName) | Urgency: \(urgency) | Reason: \(reason.prefix(50))")
    }
    
    func logCloudKitSync(entityType: String, entityID: UUID, status: String, duration: TimeInterval? = nil) {
        var message = "CloudKit Sync | Type: \(entityType) | ID: \(entityID.uuidString) | Status: \(status)"
        if let duration = duration {
            message += " | Duration: \(String(format: "%.2f", duration))s"
        }
        info(message)
    }
}

// MARK: - Convenience Global Functions

func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ProductionLogger.shared.debug(message, file: file, function: function, line: line)
}

func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ProductionLogger.shared.info(message, file: file, function: function, line: line)
}

func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ProductionLogger.shared.warning(message, file: file, function: function, line: line)
}

func logError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    ProductionLogger.shared.error(message, error: error, file: file, function: function, line: line)
}

func logSuccess(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    ProductionLogger.shared.success(message, file: file, function: function, line: line)
}

func logCritical(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    ProductionLogger.shared.critical(message, error: error, file: file, function: function, line: line)
}
