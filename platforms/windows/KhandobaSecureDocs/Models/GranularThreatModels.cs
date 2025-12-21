using System;
using System.Collections.Generic;

namespace KhandobaSecureDocs.Models
{
    /// <summary>
    /// 10-level granular threat classification
    /// </summary>
    public enum GranularThreatLevel
    {
        Minimal,      // 0.0-10.0
        VeryLow,      // 10.1-20.0
        Low,          // 20.1-30.0
        LowMedium,    // 30.1-40.0
        Medium,       // 40.1-50.0
        MediumHigh,   // 50.1-60.0
        High,         // 60.1-70.0
        HighCritical, // 70.1-80.0
        Critical,     // 80.1-90.0
        Extreme       // 90.1-100.0
    }
    
    public static class GranularThreatLevelExtensions
    {
        public static string DisplayName(this GranularThreatLevel level) => level switch
        {
            GranularThreatLevel.Minimal => "Minimal",
            GranularThreatLevel.VeryLow => "Very Low",
            GranularThreatLevel.Low => "Low",
            GranularThreatLevel.LowMedium => "Low-Medium",
            GranularThreatLevel.Medium => "Medium",
            GranularThreatLevel.MediumHigh => "Medium-High",
            GranularThreatLevel.High => "High",
            GranularThreatLevel.HighCritical => "High-Critical",
            GranularThreatLevel.Critical => "Critical",
            GranularThreatLevel.Extreme => "Extreme",
            _ => "Unknown"
        };
        
        public static int NumericValue(this GranularThreatLevel level) => (int)level + 1;
        
        public static bool RequiresAction(this GranularThreatLevel level) => level.NumericValue() >= 6;
        
        public static bool RequiresImmediateAction(this GranularThreatLevel level) => level.NumericValue() >= 8;
        
        public static GranularThreatLevel FromScore(double score) => score switch
        {
            < 10.1 => GranularThreatLevel.Minimal,
            < 20.1 => GranularThreatLevel.VeryLow,
            < 30.1 => GranularThreatLevel.Low,
            < 40.1 => GranularThreatLevel.LowMedium,
            < 50.1 => GranularThreatLevel.Medium,
            < 60.1 => GranularThreatLevel.MediumHigh,
            < 70.1 => GranularThreatLevel.High,
            < 80.1 => GranularThreatLevel.HighCritical,
            < 90.1 => GranularThreatLevel.Critical,
            _ => GranularThreatLevel.Extreme
        };
    }
    
    /// <summary>
    /// Logic component scores (7 logic types)
    /// </summary>
    public record LogicComponentScores(
        double DeductiveScore,
        double InductiveScore,
        double AbductiveScore,
        double StatisticalScore,
        double AnalogicalScore,
        double TemporalScore,
        double ModalScore
    );
    
    /// <summary>
    /// Threat category scores (7 categories)
    /// </summary>
    public record ThreatCategoryScores(
        double AccessPatternScore,
        double GeographicScore,
        double DocumentContentScore,
        double BehavioralScore,
        double ExternalThreatScore,
        double ComplianceScore,
        double DataExfiltrationScore
    );
    
    /// <summary>
    /// Granular threat scores with component breakdowns
    /// </summary>
    public record GranularThreatScores(
        double CompositeScore, // 0-100, 2 decimal precision
        LogicComponentScores LogicScores,
        ThreatCategoryScores CategoryScores,
        List<InferenceContribution> InferenceContributions,
        double? ScoreDelta = null, // Change from last assessment
        double? ScoreVelocity = null // Rate of change
    );
    
    /// <summary>
    /// Threat category enum
    /// </summary>
    public enum ThreatCategory
    {
        AccessPattern,
        Geographic,
        DocumentContent,
        Behavioral,
        ExternalThreat,
        Compliance,
        DataExfiltration
    }
    
    public static class ThreatCategoryExtensions
    {
        public static string Description(this ThreatCategory category) => category switch
        {
            ThreatCategory.AccessPattern => "Access Pattern",
            ThreatCategory.Geographic => "Geographic",
            ThreatCategory.DocumentContent => "Document Content",
            ThreatCategory.Behavioral => "Behavioral",
            ThreatCategory.ExternalThreat => "External Threat",
            ThreatCategory.Compliance => "Compliance",
            ThreatCategory.DataExfiltration => "Data Exfiltration",
            _ => "Unknown"
        };
    }
    
    /// <summary>
    /// Threat impact level
    /// </summary>
    public enum ThreatImpact
    {
        Low,       // 0-25 contribution
        Medium,    // 26-50 contribution
        High,      // 51-75 contribution
        Critical   // 76-100 contribution
    }
    
    /// <summary>
    /// Urgency level for recommendations
    /// </summary>
    public enum UrgencyLevel
    {
        Immediate,  // Act within 1 hour
        Urgent,     // Act within 24 hours
        Important,  // Act within 1 week
        Routine     // Act within 1 month
    }
    
    public static class UrgencyLevelExtensions
    {
        public static string DisplayName(this UrgencyLevel urgency) => urgency switch
        {
            UrgencyLevel.Immediate => "Immediate",
            UrgencyLevel.Urgent => "Urgent",
            UrgencyLevel.Important => "Important",
            UrgencyLevel.Routine => "Routine",
            _ => "Unknown"
        };
    }
    
    /// <summary>
    /// Inference contribution to threat score
    /// </summary>
    public record InferenceContribution(
        Guid InferenceId,
        string LogicType,
        ThreatCategory Category,
        double ContributionScore, // 0-100
        double Confidence,
        ThreatImpact Impact,
        string Conclusion
    );
    
    /// <summary>
    /// Threat recommendation with priority and urgency
    /// </summary>
    public record ThreatRecommendation(
        int Priority, // 1-10 (1 = highest priority)
        ThreatCategory Category,
        string Action,
        string Rationale,
        double ExpectedImpact, // Expected score reduction if action taken
        UrgencyLevel Urgency
    );
    
    /// <summary>
    /// Threat score snapshot for history tracking
    /// </summary>
    public record ThreatScoreSnapshot(
        DateTime Timestamp,
        double CompositeScore,
        ThreatCategoryScores CategoryScores,
        LogicComponentScores LogicScores
    );
    
    /// <summary>
    /// Logical inference from formal logic engine
    /// </summary>
    public record LogicalInference(
        Guid Id,
        string Type,
        string Method,
        string Premise,
        string Observation,
        string Conclusion,
        double Confidence,
        string? Actionable = null
    );
    
    /// <summary>
    /// Complete threat inference result
    /// </summary>
    public record ThreatInferenceResult(
        Guid VaultId,
        GranularThreatScores GranularScores,
        GranularThreatLevel ThreatLevel,
        List<LogicalInference> ThreatInferences,
        ThreatCategoryScores CategoryBreakdown,
        LogicComponentScores LogicBreakdown,
        List<InferenceContribution> InferenceContributions,
        List<ThreatRecommendation> Recommendations,
        DateTime CalculatedAt,
        List<ThreatScoreSnapshot>? ScoreHistory = null
    );
}

