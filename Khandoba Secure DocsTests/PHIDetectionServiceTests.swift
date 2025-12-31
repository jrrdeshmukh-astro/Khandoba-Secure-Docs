//
//  PHIDetectionServiceTests.swift
//  Khandoba Secure DocsTests
//

import XCTest
@testable import Khandoba_Secure_Docs

@MainActor
final class PHIDetectionServiceTests: XCTestCase {
    var phiService: PHIDetectionService!
    
    override func setUp() {
        super.setUp()
        phiService = PHIDetectionService.shared
    }
    
    override func tearDown() {
        phiService = nil
        super.tearDown()
    }
    
    func testSSNDetection() async {
        let text = "Patient SSN: 123-45-6789"
        let matches = await phiService.detectPHI(in: text)
        let ssnMatches = matches.filter { $0.type == PHIType.ssn.rawValue }
        XCTAssertFalse(ssnMatches.isEmpty, "Should detect SSN")
    }
    
    func testPhoneNumberDetection() async {
        let text = "Contact: (555) 123-4567"
        let matches = await phiService.detectPHI(in: text)
        let phoneMatches = matches.filter { $0.type == PHIType.phoneNumber.rawValue }
        XCTAssertFalse(phoneMatches.isEmpty, "Should detect phone number")
    }
    
    func testEmailDetection() async {
        let text = "Contact: patient@example.com"
        let matches = await phiService.detectPHI(in: text)
        let emailMatches = matches.filter { $0.type == PHIType.email.rawValue }
        XCTAssertFalse(emailMatches.isEmpty, "Should detect email")
    }
    
    func testMultiplePHITypes() async {
        let text = "Patient: John Smith\nSSN: 123-45-6789\nDOB: 01/15/1980\nPhone: (555) 123-4567"
        let matches = await phiService.detectPHI(in: text)
        XCTAssertGreaterThan(matches.count, 2, "Should detect multiple PHI types")
    }
    
    func testEmptyTextDetection() async {
        let matches = await phiService.detectPHI(in: "")
        XCTAssertTrue(matches.isEmpty, "Empty text should return no matches")
    }
}
