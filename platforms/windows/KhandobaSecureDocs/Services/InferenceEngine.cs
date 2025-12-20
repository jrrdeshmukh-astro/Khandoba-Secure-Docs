using System;
using System.Collections.Generic;
using System.Linq;
using KhandobaSecureDocs.Models;
using KhandobaSecureDocs.Services;

namespace KhandobaSecureDocs.Services
{
    public class KnowledgeGraph
    {
        public Dictionary<string, KnowledgeNode> Nodes { get; set; } = new();
        public List<KnowledgeEdge> Edges { get; set; } = new();
    }

    public class KnowledgeNode
    {
        public string Id { get; set; } = string.Empty;
        public string Type { get; set; } = string.Empty; // "person", "organization", "document", etc.
        public string Label { get; set; } = string.Empty;
        public Dictionary<string, object> Properties { get; set; } = new();
        public int ConnectionCount { get; set; }
    }

    public class KnowledgeEdge
    {
        public string Source { get; set; } = string.Empty;
        public string Target { get; set; } = string.Empty;
        public string Relationship { get; set; } = string.Empty;
        public double Weight { get; set; } = 1.0;
    }

    public class Inference
    {
        public string Type { get; set; } = string.Empty;
        public string Conclusion { get; set; } = string.Empty;
        public List<string> Evidence { get; set; } = new();
        public double Confidence { get; set; }
        public string Action { get; set; } = string.Empty;
    }

    public class InferenceEngine
    {
        private readonly FormalLogicEngine _logicEngine;
        private KnowledgeGraph? _knowledgeGraph;

        public InferenceEngine(FormalLogicEngine logicEngine)
        {
            _logicEngine = logicEngine;
        }

        public KnowledgeGraph BuildKnowledgeBase(List<Document> documents, List<DocumentIndex> indices)
        {
            var graph = new KnowledgeGraph();

            // Add document nodes
            foreach (var document in documents)
            {
                var node = new KnowledgeNode
                {
                    Id = document.Id.ToString(),
                    Type = "document",
                    Label = document.Name,
                    Properties = new Dictionary<string, object>
                    {
                        { "fileType", document.FileType },
                        { "createdAt", document.CreatedAt },
                        { "vaultId", document.VaultID }
                    }
                };
                graph.Nodes[node.Id] = node;
            }

            // Add entity nodes and edges from indices
            foreach (var index in indices)
            {
                foreach (var entity in index.Entities)
                {
                    var nodeId = $"entity_{entity.Text}";
                    if (!graph.Nodes.ContainsKey(nodeId))
                    {
                        graph.Nodes[nodeId] = new KnowledgeNode
                        {
                            Id = nodeId,
                            Type = entity.Category.ToLower(),
                            Label = entity.Text,
                            Properties = new Dictionary<string, object>
                            {
                                { "confidence", entity.Confidence }
                            }
                        };
                    }

                    // Create edge: document -> entity
                    graph.Edges.Add(new KnowledgeEdge
                    {
                        Source = index.DocumentId.ToString(),
                        Target = nodeId,
                        Relationship = "contains",
                        Weight = entity.Confidence
                    });
                }
            }

            // Calculate connection counts
            foreach (var node in graph.Nodes.Values)
            {
                node.ConnectionCount = graph.Edges.Count(e => e.Source == node.Id || e.Target == node.Id);
            }

            _knowledgeGraph = graph;
            return graph;
        }

        public List<Inference> GenerateInferences(KnowledgeGraph graph, List<Document> documents)
        {
            var inferences = new List<Inference>();

            // Rule 1: Network Analysis
            inferences.AddRange(ApplyNetworkAnalysis(graph));

            // Rule 2: Temporal Patterns
            inferences.AddRange(ApplyTemporalPatterns(documents));

            // Rule 3: Document Chains
            inferences.AddRange(ApplyDocumentChains(graph, documents));

            // Rule 4: Anomaly Detection
            inferences.AddRange(ApplyAnomalyDetection(graph, documents));

            // Rule 5: Risk Assessment
            inferences.AddRange(ApplyRiskAssessment(graph, documents));

            // Rule 6: Source/Sink Correlation
            inferences.AddRange(ApplySourceSinkCorrelation(documents));

            return inferences;
        }

        private List<Inference> ApplyNetworkAnalysis(KnowledgeGraph graph)
        {
            var inferences = new List<Inference>();

            // Find highly connected nodes (key entities)
            var keyNodes = graph.Nodes.Values
                .Where(n => n.ConnectionCount > 5)
                .OrderByDescending(n => n.ConnectionCount)
                .Take(5);

            foreach (var node in keyNodes)
            {
                inferences.Add(new Inference
                {
                    Type = "network_analysis",
                    Conclusion = $"{node.Label} is a key entity (connected to {node.ConnectionCount} items)",
                    Evidence = new List<string> { $"Connection count: {node.ConnectionCount}" },
                    Confidence = Math.Min(node.ConnectionCount / 10.0, 0.95),
                    Action = "Review documents related to this entity"
                });
            }

            return inferences;
        }

        private List<Inference> ApplyTemporalPatterns(List<Document> documents)
        {
            var inferences = new List<Inference>();

            // Group documents by time periods
            var recentDocs = documents.Where(d => d.CreatedAt > DateTime.UtcNow.AddDays(-7)).ToList();
            if (recentDocs.Count > 5)
            {
                inferences.Add(new Inference
                {
                    Type = "temporal_pattern",
                    Conclusion = "High activity in the last 7 days",
                    Evidence = new List<string> { $"{recentDocs.Count} documents created recently" },
                    Confidence = 0.75,
                    Action = "Review recent document activity"
                });
            }

            return inferences;
        }

        private List<Inference> ApplyDocumentChains(KnowledgeGraph graph, List<Document> documents)
        {
            var inferences = new List<Inference>();

            // Find documents connected through shared entities
            var documentGroups = new Dictionary<string, List<string>>();
            foreach (var edge in graph.Edges.Where(e => graph.Nodes[e.Source].Type == "document"))
            {
                var docId = edge.Source;
                var entityId = edge.Target;
                if (!documentGroups.ContainsKey(entityId))
                {
                    documentGroups[entityId] = new List<string>();
                }
                documentGroups[entityId].Add(docId);
            }

            foreach (var group in documentGroups.Where(g => g.Value.Count > 2))
            {
                inferences.Add(new Inference
                {
                    Type = "document_chain",
                    Conclusion = $"{group.Value.Count} documents are related through shared entity",
                    Evidence = new List<string> { $"Entity: {graph.Nodes[group.Key].Label}" },
                    Confidence = 0.80,
                    Action = "Review related documents together"
                });
            }

            return inferences;
        }

        private List<Inference> ApplyAnomalyDetection(KnowledgeGraph graph, List<Document> documents)
        {
            var inferences = new List<Inference>();

            // Detect unusual access patterns, file types, etc.
            var fileTypeGroups = documents.GroupBy(d => d.FileType);
            var commonTypes = fileTypeGroups.OrderByDescending(g => g.Count()).Take(3).Select(g => g.Key).ToList();

            var unusualDocs = documents.Where(d => !commonTypes.Contains(d.FileType)).ToList();
            if (unusualDocs.Any())
            {
                inferences.Add(new Inference
                {
                    Type = "anomaly_detection",
                    Conclusion = $"Unusual file types detected: {string.Join(", ", unusualDocs.Select(d => d.FileType).Distinct())}",
                    Evidence = new List<string> { $"{unusualDocs.Count} documents with uncommon file types" },
                    Confidence = 0.70,
                    Action = "Review unusual documents for security"
                });
            }

            return inferences;
        }

        private List<Inference> ApplyRiskAssessment(KnowledgeGraph graph, List<Document> documents)
        {
            var inferences = new List<Inference>();

            // Assess risk based on document count, types, entities
            var totalDocs = documents.Count;
            var hasSensitiveEntities = graph.Nodes.Values.Any(n => 
                n.Type == "person" || n.Type == "organization");

            if (totalDocs > 50 && hasSensitiveEntities)
            {
                inferences.Add(new Inference
                {
                    Type = "risk_assessment",
                    Conclusion = "High-value vault detected",
                    Evidence = new List<string> 
                    { 
                        $"Large document count: {totalDocs}",
                        "Contains sensitive entities"
                    },
                    Confidence = 0.85,
                    Action = "Enable dual-key authentication"
                });
            }

            return inferences;
        }

        private List<Inference> ApplySourceSinkCorrelation(List<Document> documents)
        {
            var inferences = new List<Inference>();

            var sourceDocs = documents.Where(d => d.DocumentType == "source").Count();
            var sinkDocs = documents.Where(d => d.DocumentType == "sink").Count();

            if (sourceDocs > 0 && sinkDocs > 0)
            {
                inferences.Add(new Inference
                {
                    Type = "source_sink_correlation",
                    Conclusion = "Vault contains both source and sink documents",
                    Evidence = new List<string>
                    {
                        $"Source documents: {sourceDocs}",
                        $"Sink documents: {sinkDocs}"
                    },
                    Confidence = 0.75,
                    Action = "Review document flow patterns"
                });
            }

            return inferences;
        }

        public List<string> DetectPatterns(KnowledgeGraph graph, List<Document> documents)
        {
            var patterns = new List<string>();

            // Communication chains
            var communicationChains = DetectCommunicationChains(graph);
            patterns.AddRange(communicationChains);

            // Geographic patterns
            var geographicPatterns = DetectGeographicPatterns(documents);
            patterns.AddRange(geographicPatterns);

            // Temporal sequences
            var temporalSequences = DetectTemporalSequences(documents);
            patterns.AddRange(temporalSequences);

            return patterns;
        }

        private List<string> DetectCommunicationChains(KnowledgeGraph graph)
        {
            // Find paths between person entities through documents
            var personNodes = graph.Nodes.Values.Where(n => n.Type == "person").ToList();
            var chains = new List<string>();

            for (int i = 0; i < personNodes.Count; i++)
            {
                for (int j = i + 1; j < personNodes.Count; j++)
                {
                    var path = FindPath(graph, personNodes[i].Id, personNodes[j].Id);
                    if (path.Count > 0)
                    {
                        chains.Add($"Communication chain: {personNodes[i].Label} ↔ {personNodes[j].Label}");
                    }
                }
            }

            return chains;
        }

        private List<string> DetectGeographicPatterns(List<Document> documents)
        {
            // Would need location data in documents
            return new List<string>();
        }

        private List<string> DetectTemporalSequences(List<Document> documents)
        {
            var sequences = new List<string>();
            var sortedDocs = documents.OrderBy(d => d.CreatedAt).ToList();

            if (sortedDocs.Count > 3)
            {
                sequences.Add($"Temporal sequence: {sortedDocs.Count} documents in chronological order");
            }

            return sequences;
        }

        private List<string> FindPath(KnowledgeGraph graph, string source, string target)
        {
            // Simple BFS path finding
            var queue = new Queue<(string node, List<string> path)>();
            queue.Enqueue((source, new List<string> { source }));
            var visited = new HashSet<string> { source };

            while (queue.Count > 0)
            {
                var (current, path) = queue.Dequeue();

                if (current == target)
                {
                    return path;
                }

                foreach (var edge in graph.Edges.Where(e => e.Source == current || e.Target == current))
                {
                    var next = edge.Source == current ? edge.Target : edge.Source;
                    if (!visited.Contains(next))
                    {
                        visited.Add(next);
                        var newPath = new List<string>(path) { next };
                        queue.Enqueue((next, newPath));
                    }
                }
            }

            return new List<string>();
        }
    }
}
