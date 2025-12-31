//
//  IndexCalculationServiceTests.swift
//  Khandoba Secure DocsTests
//

import XCTest
import SwiftData
@testable import Khandoba_Secure_Docs

@MainActor
final class IndexCalculationServiceTests: XCTestCase {
    var indexService: IndexCalculationService!
    var threatService: ThreatMonitoringService!
    var complianceService: ComplianceEngineService!
    var riskService: RiskAssessmentService!
    var modelContext: ModelContext!
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([ComplianceRecord.self, RiskAssessment.self, VaultAccessLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
        indexService = IndexCalculationService.shared
        threatService = ThreatMonitoringService()
        complianceService = ComplianceEngineService.shared
        riskService = RiskAssessmentService.shared
        complianceService.configure(modelContext: modelContext, threatMonitoringService: threatService)
        riskService.configure(modelContext: modelContext, threatMonitoringService: threatService, complianceEngineService: complianceService)
        indexService.configure(modelContext: modelContext, threatMonitoringService: threatService, complianceEngineService: complianceService, riskAssessmentService: riskService)
    }
    
    override func tearDown() {
        indexService = nil
        threatService = nil
        complianceService = nil
        riskService = nil
        modelContext = nil
        modelContainer = nil
        super.tearDown()
    }
    
    func testCalculateAllIndexes() async {
        await indexService.calculateAllIndexes()
        let indexes = indexService.currentIndexes
        XCTAssertGreaterThanOrEqual(indexes.threatIndex, 0.0)
        XCTAssertLessThanOrEqual(indexes.threatIndex, 100.0)
        XCTAssertGreaterThanOrEqual(indexes.complianceIndex, 0.0)
        XCTAssertLessThanOrEqual(indexes.complianceIndex, 100.0)
        XCTAssertGreaterThanOrEqual(indexes.triageCriticality, 0.0)
        XCTAssertLessThanOrEqual(indexes.triageCriticality, 100.0)
    }
    
    func testIndexResultStructure() {
        let result = IndexResult(threatIndex: 50.0, complianceIndex: 75.0, triageCriticality: 60.0, calculatedAt: Date())
        XCTAssertEqual(result.threatIndex, 50.0)
        XCTAssertEqual(result.complianceIndex, 75.0)
        XCTAssertEqual(result.triageCriticality, 60.0)
        XCTAssertNotNil(result.calculatedAt)
    }
}
