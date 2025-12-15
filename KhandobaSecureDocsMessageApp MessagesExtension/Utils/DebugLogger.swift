//
//  DebugLogger.swift
//  Khandoba Secure Docs
//
//  Debug logging utility for runtime debugging
//

import Foundation

final class DebugLogger {
    static let shared = DebugLogger()
    
    private let serverEndpoint = "http://127.0.0.1:7242/ingest/ee110eef-1d30-4afd-a7a5-832daedaec3f"
    private let logPath = "/Users/jaideshmukh/Desktop/Khandoba Secure Docs/.cursor/debug.log"
    
    private init() {}
    
    func log(
        location: String,
        message: String,
        data: [String: Any],
        sessionId: String = "debug-session",
        runId: String = "run1",
        hypothesisId: String? = nil
    ) {
        // Always print to console first for immediate visibility
        print("🔍 [DEBUG] \(location): \(message) | Data: \(data)")
        
        let logEntry: [String: Any] = [
            "id": "log_\(Int(Date().timeIntervalSince1970))_\(UUID().uuidString.prefix(8))",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "location": location,
            "message": message,
            "data": data,
            "sessionId": sessionId,
            "runId": runId,
            "hypothesisId": hypothesisId ?? ""
        ]
        
        // Write to file (NDJSON format) - ensure directory exists
        do {
            if let jsonData = try? JSONSerialization.data(withJSONObject: logEntry),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                let logURL = URL(fileURLWithPath: logPath)
                let logDir = logURL.deletingLastPathComponent()
                
                // Create directory if needed
                try? FileManager.default.createDirectory(at: logDir, withIntermediateDirectories: true, attributes: nil)
                
                // Append to file
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    defer { fileHandle.closeFile() }
                    fileHandle.seekToEndOfFile()
                    if let data = (jsonString + "\n").data(using: .utf8) {
                        fileHandle.write(data)
                    }
                } else {
                    // Create file if it doesn't exist
                    try? (jsonString + "\n").write(toFile: logPath, atomically: false, encoding: .utf8)
                }
            }
        } catch {
            print("❌ [DEBUG] Failed to write log: \(error.localizedDescription)")
        }
        
        // Also send via HTTP (non-blocking)
        if let url = URL(string: serverEndpoint),
           let jsonData = try? JSONSerialization.data(withJSONObject: logEntry) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            request.timeoutInterval = 1.0
            
            URLSession.shared.dataTask(with: request).resume()
        }
    }
}

// Convenience functions
func debugLog(
    _ message: String,
    location: String = #file + ":" + String(#line),
    data: [String: Any] = [:],
    hypothesisId: String? = nil
) {
    DebugLogger.shared.log(
        location: location,
        message: message,
        data: data,
        hypothesisId: hypothesisId
    )
}
