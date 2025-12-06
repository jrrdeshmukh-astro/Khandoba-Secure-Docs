//
//  DocumentIndexingService.swift
//  Khandoba Secure Docs
//
//  Created by Jai Deshmukh on 12/4/25.
//

import Foundation
import Combine
import NaturalLanguage
import CoreML
import Vision
import SwiftData

@MainActor
final class DocumentIndexingService: ObservableObject {
    @Published var isIndexing = false
    @Published var indexProgress: Double = 0.0
    
    private var modelContext: ModelContext?
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .language])
    // Sentiment analysis - optional feature (requires trained model)
    private var sentimentPredictor: NLModel?
    
    nonisolated init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Comprehensive Document Indexing
    
    /// Index document with ML-based analysis
    func indexDocument(_ document: Document) async throws -> DocumentIndex {
        isIndexing = true
        defer { isIndexing = false }
        
        print(" Indexing document: \(document.name)")
        
        // Extract text content
        let text = await extractText(from: document)
        
        // Step 1: Language detection
        let language = detectLanguage(text)
        
        // Step 2: Entity extraction (names, places, organizations)
        let entities = extractEntities(from: text)
        
        // Step 3: Auto-generate tags using ML
        let tags = await generateSmartTags(from: text, entities: entities)
        
        // Step 4: Suggest improved name
        let suggestedName = generateSmartName(from: text, entities: entities, currentName: document.name)
        
        // Step 5: Extract key concepts
        let keyConcepts = extractKeyConcepts(from: text)
        
        // Step 6: Sentiment analysis
        let sentiment = analyzeSentiment(text)
        
        // Step 7: Topic classification
        let topics = classifyTopics(text)
        
        // Step 8: Extract dates and temporal references
        let temporalData = extractTemporalData(from: text)
        
        // Step 9: Extract relationships (people, orgs, locations)
        let relationships = extractRelationships(from: text, entities: entities)
        
        // Step 10: Calculate importance score
        let importance = calculateImportance(
            entities: entities,
            keyConcepts: keyConcepts,
            sentiment: sentiment,
            topics: topics
        )
        
        // Create comprehensive index
        let index = DocumentIndex(
            documentID: document.id,
            documentTitle: document.name,
            suggestedName: suggestedName,
            language: language,
            entities: entities,
            tags: tags,
            keyConcepts: keyConcepts,
            sentiment: sentiment,
            topics: topics,
            temporalData: temporalData,
            relationships: relationships,
            importanceScore: importance,
            wordCount: text.split(separator: " ").count,
            indexedAt: Date()
        )
        
        // Update document with generated metadata
        document.aiTags = tags
        
        if let modelContext = modelContext {
            modelContext.insert(index)
            try modelContext.save()
        }
        
        print(" Document indexed: \(tags.count) tags, \(entities.count) entities")
        
        return index
    }
    
    // MARK: - Text Extraction
    
    private func extractText(from document: Document) async -> String {
        // Use PDFTextExtractor for comprehensive text extraction
        let extractedText = await PDFTextExtractor.extractText(from: document)
        
        // Combine with metadata for better analysis
        var fullText = extractedText
        
        if !fullText.contains(document.name) {
            fullText = document.name + "\n" + fullText
        }
        
        // Document description not available in model
        // Additional metadata could be added here if needed
        
        return fullText
    }
    
    // MARK: - Language Detection
    
    private func detectLanguage(_ text: String) -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        
        if let language = recognizer.dominantLanguage {
            return language.rawValue
        }
        
        return "en" // Default to English
    }
    
    // MARK: - Entity Extraction
    
    private func extractEntities(from text: String) -> [DocumentEntity] {
        var entities: [DocumentEntity] = []
        
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if let tag = tag {
                let entity = String(text[tokenRange])
                
                let entityType: EntityType
                switch tag {
                case .personalName:
                    entityType = .person
                case .placeName:
                    entityType = .location
                case .organizationName:
                    entityType = .organization
                default:
                    entityType = .other
                }
                
                entities.append(DocumentEntity(
                    text: entity,
                    type: entityType,
                    confidence: 0.85 // NLTagger doesn't provide confidence, use default
                ))
            }
            
            return true
        }
        
        // Deduplicate entities
        var uniqueEntities: [DocumentEntity] = []
        var seen = Set<String>()
        
        for entity in entities {
            let key = "\(entity.type)_\(entity.text.lowercased())"
            if !seen.contains(key) {
                seen.insert(key)
                uniqueEntities.append(entity)
            }
        }
        
        return uniqueEntities
    }
    
    // MARK: - Smart Tag Generation
    
    private func generateSmartTags(from text: String, entities: [DocumentEntity]) async -> [String] {
        var tags: Set<String> = []
        
        // Extract nouns as potential tags
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        let options: NLTagger.Options = [.omitWhitespace, .omitPunctuation]
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if tag == .noun {
                let word = String(text[tokenRange]).lowercased()
                
                // Filter out common words
                if word.count > 3 && !commonWords.contains(word) {
                    tags.insert(word)
                }
            }
            return true
        }
        
        // Add entity-based tags
        for entity in entities {
            switch entity.type {
            case .person:
                tags.insert("people")
            case .organization:
                tags.insert("organizations")
            case .location:
                tags.insert("locations")
            case .date:
                tags.insert("dates")
            case .other:
                break
            }
        }
        
        // Add domain-specific tags
        let domainTags = classifyDomain(text)
        tags.formUnion(domainTags)
        
        // Limit to top 10 most relevant tags
        return Array(tags.sorted()).prefix(10).map { $0 }
    }
    
    // MARK: - Smart Name Generation
    
    private func generateSmartName(from text: String, entities: [DocumentEntity], currentName: String) -> String {
        // If current name is good, keep it
        if currentName.count > 10 && !currentName.contains("Untitled") {
            return currentName
        }
        
        // Extract first sentence as potential name
        let sentences = text.split(separator: ".")
        if let firstSentence = sentences.first, firstSentence.count > 10 && firstSentence.count < 100 {
            return String(firstSentence).trimmingCharacters(in: .whitespaces)
        }
        
        // Use most prominent entities
        if let firstPerson = entities.first(where: { $0.type == .person }),
           let firstOrg = entities.first(where: { $0.type == .organization }) {
            return "\(firstPerson.text) - \(firstOrg.text)"
        }
        
        // Fallback to first line
        let firstLine = text.split(separator: "\n").first ?? ""
        if firstLine.count > 0 {
            return String(firstLine.prefix(50))
        }
        
        return currentName
    }
    
    // MARK: - Key Concepts Extraction
    
    private func extractKeyConcepts(from text: String) -> [String] {
        let embedding = NLEmbedding.wordEmbedding(for: .english)
        var concepts: [String: Double] = [:] // concept: relevance score
        
        // Extract significant noun phrases
        let words = text.split(separator: " ").map { String($0).lowercased() }
        
        for word in words where word.count > 4 {
            if let vector = embedding?.vector(for: word) {
                // Calculate relevance based on embedding strength
                let magnitude = vector.reduce(0.0) { $0 + ($1 * $1) }
                concepts[word] = sqrt(magnitude)
            }
        }
        
        // Return top 5 concepts
        return concepts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    // MARK: - Sentiment Analysis
    
    private func analyzeSentiment(_ text: String) -> Double {
        guard let predictor = sentimentPredictor else {
            // Sentiment predictor not available
            return 0.0
        }
        
        do {
            let prediction = try predictor.predictedLabel(for: text)
            
            // Convert to score: -1.0 (very negative) to 1.0 (very positive)
            if let label = prediction {
                switch label {
                case "Positive": return 0.75
                case "Negative": return -0.75
                case "Neutral": return 0.0
                default: return 0.0
                }
            }
        } catch {
            print("Sentiment analysis error: \(error)")
        }
        
        return 0.0 // Neutral
    }
    
    // MARK: - Topic Classification
    
    private func classifyTopics(_ text: String) -> [String] {
        var topics: [String] = []
        let lowercased = text.lowercased()
        
        // Legal documents
        if containsAny(lowercased, keywords: ["contract", "agreement", "legal", "terms", "clause", "liability", "lawsuit", "court"]) {
            topics.append("legal")
        }
        
        // Financial documents
        if containsAny(lowercased, keywords: ["financial", "budget", "revenue", "expense", "profit", "investment", "tax", "invoice"]) {
            topics.append("financial")
        }
        
        // Medical documents
        if containsAny(lowercased, keywords: ["patient", "medical", "health", "diagnosis", "treatment", "prescription", "doctor", "hospital"]) {
            topics.append("medical")
        }
        
        // Technical documents
        if containsAny(lowercased, keywords: ["technical", "specification", "code", "software", "api", "database", "server", "algorithm"]) {
            topics.append("technical")
        }
        
        // Business documents
        if containsAny(lowercased, keywords: ["business", "meeting", "proposal", "strategy", "market", "client", "sales", "marketing"]) {
            topics.append("business")
        }
        
        // Confidential/sensitive
        if containsAny(lowercased, keywords: ["confidential", "secret", "private", "classified", "sensitive", "restricted"]) {
            topics.append("confidential")
        }
        
        return topics
    }
    
    // MARK: - Temporal Data Extraction
    
    private func extractTemporalData(from text: String) -> [TemporalReference] {
        var temporalData: [TemporalReference] = []
        
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let nsText = text as NSString
        let range = NSRange(location: 0, length: nsText.length)
        
        detector?.enumerateMatches(in: text, range: range) { match, _, _ in
            if let match = match, let date = match.date {
                temporalData.append(TemporalReference(
                    date: date,
                    context: extractContext(from: text, range: match.range),
                    type: .explicit
                ))
            }
        }
        
        return temporalData
    }
    
    // MARK: - Relationship Extraction
    
    private func extractRelationships(from text: String, entities: [DocumentEntity]) -> [DocumentRelationship] {
        var relationships: [DocumentRelationship] = []
        
        // Find co-occurring entities (simplified relationship detection)
        let sentences = text.split(separator: ".")
        
        for sentence in sentences {
            let sentenceText = String(sentence)
            var entitiesInSentence: [DocumentEntity] = []
            
            for entity in entities {
                if sentenceText.contains(entity.text) {
                    entitiesInSentence.append(entity)
                }
            }
            
            // Create relationships between co-occurring entities
            if entitiesInSentence.count >= 2 {
                for i in 0..<entitiesInSentence.count - 1 {
                    for j in (i + 1)..<entitiesInSentence.count {
                        relationships.append(DocumentRelationship(
                            entity1: entitiesInSentence[i].text,
                            entity2: entitiesInSentence[j].text,
                            relationType: inferRelationType(
                                entity1: entitiesInSentence[i],
                                entity2: entitiesInSentence[j],
                                context: sentenceText
                            ),
                            confidence: 0.7,
                            context: String(sentenceText.prefix(200))
                        ))
                    }
                }
            }
        }
        
        // Deduplicate relationships
        var uniqueRelationships: [DocumentRelationship] = []
        var seen = Set<String>()
        
        for rel in relationships {
            let key = "\(rel.entity1)_\(rel.entity2)_\(rel.relationType)"
            if !seen.contains(key) {
                seen.insert(key)
                uniqueRelationships.append(rel)
            }
        }
        
        return uniqueRelationships
    }
    
    // MARK: - Importance Scoring
    
    private func calculateImportance(
        entities: [DocumentEntity],
        keyConcepts: [String],
        sentiment: Double,
        topics: [String]
    ) -> Double {
        var score: Double = 50.0 // Base importance
        
        // More entities = more important
        score += Double(min(entities.count, 20)) * 1.5
        
        // Key concepts add importance
        score += Double(keyConcepts.count) * 2.0
        
        // Confidential topics = very important
        if topics.contains("confidential") || topics.contains("legal") {
            score += 20.0
        }
        
        // Financial/medical = important
        if topics.contains("financial") || topics.contains("medical") {
            score += 15.0
        }
        
        // Extreme sentiment = potentially important
        if abs(sentiment) > 0.5 {
            score += 10.0
        }
        
        return min(score, 100.0)
    }
    
    // MARK: - Helper Functions
    
    private func classifyDomain(_ text: String) -> Set<String> {
        var domains: Set<String> = []
        let lowercased = text.lowercased()
        
        // Legal
        if containsAny(lowercased, keywords: ["contract", "agreement", "legal", "lawsuit"]) {
            domains.insert("legal")
        }
        
        // Financial
        if containsAny(lowercased, keywords: ["financial", "money", "payment", "invoice"]) {
            domains.insert("financial")
        }
        
        // Medical
        if containsAny(lowercased, keywords: ["medical", "health", "patient", "doctor"]) {
            domains.insert("medical")
        }
        
        // Technical
        if containsAny(lowercased, keywords: ["software", "code", "api", "database"]) {
            domains.insert("technical")
        }
        
        return domains
    }
    
    private func containsAny(_ text: String, keywords: [String]) -> Bool {
        keywords.contains { text.contains($0) }
    }
    
    private func extractContext(from text: String, range: NSRange) -> String {
        let nsText = text as NSString
        let contextRange = NSRange(
            location: max(0, range.location - 50),
            length: min(100, nsText.length - range.location)
        )
        return nsText.substring(with: contextRange)
    }
    
    private func inferRelationType(
        entity1: DocumentEntity,
        entity2: DocumentEntity,
        context: String
    ) -> String {
        // Simple heuristics for relationship types
        if entity1.type == .person && entity2.type == .organization {
            if context.lowercased().contains("works") || context.lowercased().contains("employed") {
                return "works_at"
            }
            return "associated_with"
        }
        
        if entity1.type == .person && entity2.type == .person {
            return "mentioned_with"
        }
        
        if entity1.type == .organization && entity2.type == .location {
            return "located_in"
        }
        
        return "related_to"
    }
    
    private let commonWords = Set([
        "the", "and", "for", "that", "this", "with", "from", "have", "been",
        "which", "their", "would", "there", "could", "other", "than", "then",
        "them", "these", "some", "time", "very", "when", "your", "what"
    ])
}

// MARK: - Models

@Model
final class DocumentIndex {
    @Attribute(.unique) var id: UUID
    var documentID: UUID
    var documentTitle: String
    var suggestedName: String
    var language: String
    var entities: [DocumentEntity]
    var tags: [String]
    var keyConcepts: [String]
    var sentiment: Double
    var topics: [String]
    var temporalData: [TemporalReference]
    var relationships: [DocumentRelationship]
    var importanceScore: Double
    var wordCount: Int
    var indexedAt: Date
    
    init(
        id: UUID = UUID(),
        documentID: UUID,
        documentTitle: String,
        suggestedName: String,
        language: String,
        entities: [DocumentEntity],
        tags: [String],
        keyConcepts: [String],
        sentiment: Double,
        topics: [String],
        temporalData: [TemporalReference],
        relationships: [DocumentRelationship],
        importanceScore: Double,
        wordCount: Int,
        indexedAt: Date
    ) {
        self.id = id
        self.documentID = documentID
        self.documentTitle = documentTitle
        self.suggestedName = suggestedName
        self.language = language
        self.entities = entities
        self.tags = tags
        self.keyConcepts = keyConcepts
        self.sentiment = sentiment
        self.topics = topics
        self.temporalData = temporalData
        self.relationships = relationships
        self.importanceScore = importanceScore
        self.wordCount = wordCount
        self.indexedAt = indexedAt
    }
}

struct DocumentEntity: Codable, Hashable {
    let text: String
    let type: EntityType
    let confidence: Double
}

enum EntityType: String, Codable {
    case person
    case organization
    case location
    case date
    case other
}

struct TemporalReference: Codable {
    let date: Date
    let context: String
    let type: TemporalType
}

enum TemporalType: String, Codable {
    case explicit // "January 15, 2025"
    case relative // "last week", "tomorrow"
    case range    // "Q4 2024"
}

struct DocumentRelationship: Codable {
    let entity1: String
    let entity2: String
    let relationType: String // "works_at", "located_in", "associated_with"
    let confidence: Double
    let context: String
}

