//
//  ComplianceEngineServiceTests.swift
//  Khandoba Secure DocsTests
//

import XCTest
import SwiftData
@testable import Khandoba_Secure_Docs

@MainActor
final class ComplianceEngineServiceTests: XCTestCase {
    var complianceService: ComplianceEngineService!
    var threatService: ThreatMonitoringService!
    var modelContext: ModelContext!
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([ComplianceRecord.self, ComplianceControl.self, AuditFinding.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
        complianceService = ComplianceEngineService.shared
        threatService = ThreatMonitoringService()
        complianceService.configure(modelContext: modelContext, threatMonitoringService: threatService)
    }
    
    override func tearDown() {
        complianceService = nil
        threatService = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    func testComplianceFrameworkDisplayNames() {
        XCTAssertEqual(ComplianceFramework.soc2.displayName, "SOC 2")
        XCTAssertEqual(ComplianceFramework.hipaa.displayName, "HIPAA")
        XCTAssertEqual(ComplianceFramework.nist80053.displayName, "NIST 800-53")
    }
    
    func testInitializeComplianceRecords() throws {
        try complianceService.initializeComplianceRecords()
        for framework in ComplianceFramework.allCases {
            let record = complianceService.getRecord(for: framework)
            XCTAssertNotNil(record, "Record should exist for \(framework.rawValue)")
            XCTAssertEqual(record?.framework, framework.rawValue)
        }
    }
    
    func testComplianceRecordCreation() {
        let record = ComplianceRecord(framework: .hipaa, status: .notAssessed, riskScore: 0.5)
        XCTAssertEqual(record.framework, ComplianceFramework.hipaa.rawValue)
        XCTAssertEqual(record.status, ComplianceStatus.notAssessed.rawValue)
        XCTAssertEqual(record.riskScore, 0.5)
    }
    
    func testAddAuditFinding() throws {
        try complianceService.initializeComplianceRecords()
        try complianceService.addAuditFinding(to: .hipaa, title: "PHI Exposure", description: "PHI found", severity: "High")
        let record = complianceService.getRecord(for: .hipaa)
        let findings = record?.auditFindings ?? []
        XCTAssertFalse(findings.isEmpty)
        XCTAssertEqual(findings.first?.title, "PHI Exposure")
    }
    
    func testCalculateComplianceStatus() throws {
        try complianceService.initializeComplianceRecords()
        let (status, score) = complianceService.calculateComplianceStatus()
        XCTAssertNotNil(status)
        XCTAssertGreaterThanOrEqual(score, 0.0)
        XCTAssertLessThanOrEqual(score, 1.0)
    }
}
