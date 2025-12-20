using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Azure;
using Azure.AI.TextAnalytics;
using KhandobaSecureDocs.Config;

namespace KhandobaSecureDocs.Services
{
    public class DocumentIndex
    {
        public Guid DocumentId { get; set; }
        public string Language { get; set; } = "en";
        public List<EntityInfo> Entities { get; set; } = new();
        public List<string> KeyPhrases { get; set; } = new();
        public string Sentiment { get; set; } = "neutral";
        public List<string> AiTags { get; set; } = new();
        public string? SuggestedName { get; set; }
        public double ImportanceScore { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class EntityInfo
    {
        public string Text { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public double Confidence { get; set; }
    }

    public class DocumentIndexingService
    {
        private readonly TextAnalyticsClient? _textAnalyticsClient;

        public DocumentIndexingService()
        {
            // Initialize Azure Cognitive Services client
            try
            {
                if (!string.IsNullOrEmpty(AppConfig.AzureCognitiveServicesEndpoint) && 
                    !string.IsNullOrEmpty(AppConfig.AzureCognitiveServicesKey) &&
                    AppConfig.AzureCognitiveServicesEndpoint != "https://your-region.cognitiveservices.azure.com/")
                {
                    var endpoint = new Uri(AppConfig.AzureCognitiveServicesEndpoint);
                    var credential = new AzureKeyCredential(AppConfig.AzureCognitiveServicesKey);
                    _textAnalyticsClient = new TextAnalyticsClient(endpoint, credential);
                }
                else
                {
                    // Azure not configured - service will work in limited mode
                    _textAnalyticsClient = null;
                }
            }
            catch
            {
                // Azure not configured or invalid credentials - service will work in limited mode
                _textAnalyticsClient = null;
            }
        }

        public async Task<DocumentIndex> IndexDocumentAsync(string text, Guid documentId)
        {
            var index = new DocumentIndex
            {
                DocumentId = documentId,
                CreatedAt = DateTime.UtcNow
            };

            if (_textAnalyticsClient == null || string.IsNullOrWhiteSpace(text))
            {
                // Fallback: basic indexing without Azure
                index.Language = "en";
                index.AiTags = ExtractBasicTags(text);
                index.ImportanceScore = CalculateBasicImportance(text);
                return index;
            }

            try
            {
                // Language detection
                var languageResult = await _textAnalyticsClient.DetectLanguageAsync(text);
                index.Language = languageResult.Value.Iso6391Name;

                // Entity extraction
                var entitiesResult = await _textAnalyticsClient.RecognizeEntitiesAsync(text);
                index.Entities = entitiesResult.Value.Select(e => new EntityInfo
                {
                    Text = e.Text,
                    Category = e.Category.ToString(),
                    Confidence = e.ConfidenceScore
                }).ToList();

                // Key phrase extraction
                var keyPhrasesResult = await _textAnalyticsClient.ExtractKeyPhrasesAsync(text);
                index.KeyPhrases = keyPhrasesResult.Value.ToList();

                // Sentiment analysis
                var sentimentResult = await _textAnalyticsClient.AnalyzeSentimentAsync(text);
                index.Sentiment = sentimentResult.Value.Sentiment.ToString();

                // Generate AI tags from entities and key phrases
                index.AiTags = GenerateTags(index.Entities, index.KeyPhrases);

                // Suggest name from key phrases and entities
                index.SuggestedName = SuggestName(index.Entities, index.KeyPhrases);

                // Calculate importance score
                index.ImportanceScore = CalculateImportanceScore(index);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ Document indexing error: {ex.Message}");
                // Fallback to basic indexing
                index.AiTags = ExtractBasicTags(text);
                index.ImportanceScore = CalculateBasicImportance(text);
            }

            return index;
        }

        private List<string> GenerateTags(List<EntityInfo> entities, List<string> keyPhrases)
        {
            var tags = new HashSet<string>();

            // Add entity-based tags
            foreach (var entity in entities)
            {
                switch (entity.Category.ToLower())
                {
                    case "person":
                        tags.Add("person");
                        tags.Add("contact");
                        break;
                    case "organization":
                        tags.Add("organization");
                        tags.Add("company");
                        break;
                    case "location":
                        tags.Add("location");
                        tags.Add("place");
                        break;
                    case "datetime":
                        tags.Add("date");
                        tags.Add("time");
                        break;
                }
            }

            // Add key phrase-based tags
            foreach (var phrase in keyPhrases.Take(5))
            {
                var normalized = phrase.ToLower().Trim();
                if (normalized.Length > 3 && normalized.Length < 20)
                {
                    tags.Add(normalized);
                }
            }

            return tags.ToList();
        }

        private string? SuggestName(List<EntityInfo> entities, List<string> keyPhrases)
        {
            // Use first organization or person entity, or first key phrase
            var org = entities.FirstOrDefault(e => e.Category == "Organization");
            if (org != null)
            {
                return $"{org.Text} Document";
            }

            var person = entities.FirstOrDefault(e => e.Category == "Person");
            if (person != null)
            {
                return $"{person.Text} Document";
            }

            if (keyPhrases.Any())
            {
                return $"{keyPhrases.First()} Document";
            }

            return null;
        }

        private double CalculateImportanceScore(DocumentIndex index)
        {
            double score = 0.5; // Base score

            // Increase score based on entities
            score += Math.Min(index.Entities.Count * 0.05, 0.2);

            // Increase score based on key phrases
            score += Math.Min(index.KeyPhrases.Count * 0.03, 0.15);

            // Adjust based on sentiment
            if (index.Sentiment == "positive")
            {
                score += 0.1;
            }

            return Math.Min(score, 1.0);
        }

        private List<string> ExtractBasicTags(string text)
        {
            var tags = new List<string>();
            var words = text.ToLower().Split(new[] { ' ', '\n', '\r', '\t' }, StringSplitOptions.RemoveEmptyEntries);
            var commonWords = new HashSet<string> { "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by" };

            var wordFreq = words
                .Where(w => w.Length > 3 && !commonWords.Contains(w))
                .GroupBy(w => w)
                .OrderByDescending(g => g.Count())
                .Take(5)
                .Select(g => g.Key);

            tags.AddRange(wordFreq);
            return tags;
        }

        private double CalculateBasicImportance(string text)
        {
            // Simple heuristic: longer documents with more words are more important
            var wordCount = text.Split(new[] { ' ', '\n', '\r', '\t' }, StringSplitOptions.RemoveEmptyEntries).Length;
            return Math.Min(wordCount / 1000.0, 1.0);
        }
    }
}
