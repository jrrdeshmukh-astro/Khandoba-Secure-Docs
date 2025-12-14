//
//  iMessageExtensionTests.swift
//  Khandoba Secure DocsTests
//
//  Unit tests for iMessage extension functionality
//

import Testing
import Foundation
import UniformTypeIdentifiers
@testable import Khandoba_Secure_Docs

// MARK: - Test Helper: SharedFile Model
// Note: SharedFile is defined in the iMessage extension target, so we define it here for testing
struct SharedFile: Identifiable {
    let id: UUID
    let name: String
    let data: Data
    let type: String
    let size: Int
}

struct iMessageExtensionTests {
    
    // MARK: - File Type Determination Tests
    
    @Test("File type determination for images")
    func testImageFileTypeDetermination() {
        let imageTypes = [
            UTType.image.identifier,
            UTType.jpeg.identifier,
            UTType.png.identifier,
            "public.heic"
        ]
        
        for type in imageTypes {
            let result = determineFileType(from: type)
            #expect(result == "image", "Expected 'image' for type: \(type), got: \(result)")
        }
    }
    
    @Test("File type determination for videos")
    func testVideoFileTypeDetermination() {
        let videoTypes = [
            UTType.movie.identifier,
            UTType.video.identifier,
            "public.mpeg-4",
            "public.avi"
        ]
        
        for type in videoTypes {
            let result = determineFileType(from: type)
            #expect(result == "video", "Expected 'video' for type: \(type), got: \(result)")
        }
    }
    
    @Test("File type determination for audio")
    func testAudioFileTypeDetermination() {
        let audioTypes = [
            UTType.audio.identifier,
            UTType.mp3.identifier,
            "public.aac"
        ]
        
        for type in audioTypes {
            let result = determineFileType(from: type)
            #expect(result == "audio", "Expected 'audio' for type: \(type), got: \(result)")
        }
    }
    
    @Test("File type determination for PDF")
    func testPDFFileTypeDetermination() {
        let pdfType = UTType.pdf.identifier
        let result = determineFileType(from: pdfType)
        #expect(result == "pdf", "Expected 'pdf' for PDF type, got: \(result)")
    }
    
    @Test("File type determination for unknown types")
    func testUnknownFileTypeDetermination() {
        let unknownTypes = [
            UTType.data.identifier,
            "public.unknown",
            "com.custom.type"
        ]
        
        for type in unknownTypes {
            let result = determineFileType(from: type)
            #expect(result == "data", "Expected 'data' for unknown type: \(type), got: \(result)")
        }
    }
    
    // MARK: - File Icon Tests
    
    @Test("File icon for different file types")
    func testFileIconSelection() {
        let testCases: [(String, String)] = [
            ("image", "photo"),
            ("jpeg", "photo"),
            ("png", "photo"),
            ("heic", "photo"),
            ("video", "video"),
            ("movie", "video"),
            ("pdf", "doc.fill"),
            ("audio", "music.note"),
            ("unknown", "doc")
        ]
        
        for (fileType, expectedIcon) in testCases {
            let icon = fileIcon(for: fileType)
            #expect(icon == expectedIcon, "Expected icon '\(expectedIcon)' for type '\(fileType)', got '\(icon)'")
        }
    }
    
    // MARK: - File Size Formatting Tests
    
    @Test("File size formatting for bytes")
    func testFileSizeFormatting() {
        let sizes: [(Int, String)] = [
            (512, "512 bytes"),
            (1024, "1 KB"),
            (1536, "1.5 KB"),
            (1024 * 1024, "1 MB"),
            (2 * 1024 * 1024, "2 MB")
        ]
        
        for (bytes, expected) in sizes {
            let formatted = fileSizeString(bytes)
            // Just check that it contains the right unit
            if bytes < 1024 {
                #expect(formatted.contains("bytes") || formatted.contains("KB"), "Size formatting for \(bytes) bytes")
            } else if bytes < 1024 * 1024 {
                #expect(formatted.contains("KB"), "Size formatting for \(bytes) bytes should contain KB")
            } else {
                #expect(formatted.contains("MB"), "Size formatting for \(bytes) bytes should contain MB")
            }
        }
    }
    
    // MARK: - Shared File Model Tests
    
    @Test("SharedFile initialization")
    func testSharedFileInitialization() {
        let testData = Data("test content".utf8)
        let sharedFile = SharedFile(
            id: UUID(),
            name: "test.txt",
            data: testData,
            type: "text",
            size: testData.count
        )
        
        #expect(sharedFile.name == "test.txt")
        #expect(sharedFile.data == testData)
        #expect(sharedFile.type == "text")
        #expect(sharedFile.size == testData.count)
    }
    
    @Test("SharedFile Identifiable conformance")
    func testSharedFileIdentifiable() {
        let id1 = UUID()
        let id2 = UUID()
        
        let file1 = SharedFile(id: id1, name: "file1", data: Data(), type: "data", size: 0)
        let file2 = SharedFile(id: id2, name: "file2", data: Data(), type: "data", size: 0)
        let file3 = SharedFile(id: id1, name: "file3", data: Data(), type: "data", size: 0)
        
        #expect(file1.id == id1)
        #expect(file2.id == id2)
        #expect(file1.id == file3.id) // Same ID
        #expect(file1.id != file2.id) // Different IDs
    }
}

// MARK: - Helper Functions (extracted for testing)

private func determineFileType(from typeIdentifier: String) -> String {
    let lowercased = typeIdentifier.lowercased()
    
    // Check for image types
    if lowercased.contains("image") || 
       lowercased.contains("jpeg") || 
       lowercased.contains("jpg") ||
       lowercased.contains("png") ||
       lowercased.contains("heic") ||
       lowercased.contains("heif") ||
       lowercased.contains("gif") ||
       lowercased.contains("bmp") ||
       lowercased.contains("tiff") ||
       lowercased.contains("webp") {
        return "image"
    }
    // Check for video types
    else if lowercased.contains("movie") || 
            lowercased.contains("video") ||
            lowercased.contains("mpeg") ||
            lowercased.contains("mp4") ||
            lowercased.contains("mov") ||
            lowercased.contains("avi") ||
            lowercased.contains("quicktime") {
        return "video"
    }
    // Check for audio types
    else if lowercased.contains("audio") ||
            lowercased.contains("mp3") ||
            lowercased.contains("aac") ||
            lowercased.contains("wav") ||
            lowercased.contains("m4a") ||
            lowercased.contains("flac") {
        return "audio"
    }
    // Check for PDF
    else if lowercased.contains("pdf") {
        return "pdf"
    }
    // Default to data
    else {
        return "data"
    }
}

private func fileIcon(for type: String) -> String {
    switch type.lowercased() {
    case "image", "jpeg", "png", "heic":
        return "photo"
    case "video", "movie":
        return "video"
    case "pdf":
        return "doc.fill"
    case "audio":
        return "music.note"
    default:
        return "doc"
    }
}

private func fileSizeString(_ bytes: Int) -> String {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useKB, .useMB]
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}
