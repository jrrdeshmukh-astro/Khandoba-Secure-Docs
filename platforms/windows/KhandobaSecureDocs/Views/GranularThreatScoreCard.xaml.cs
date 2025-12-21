using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using System;

namespace KhandobaSecureDocs.Views
{
    public sealed partial class GranularThreatScoreCard : UserControl
    {
        private bool _showDetails = false;
        
        public ThreatInferenceResult Result
        {
            get => (ThreatInferenceResult)GetValue(ResultProperty);
            set => SetValue(ResultProperty, value);
        }
        
        public static readonly DependencyProperty ResultProperty =
            DependencyProperty.Register(nameof(Result), typeof(ThreatInferenceResult), 
                typeof(GranularThreatScoreCard), new PropertyMetadata(null, OnResultChanged));
        
        public bool ShowDetails
        {
            get => (bool)GetValue(ShowDetailsProperty);
            set => SetValue(ShowDetailsProperty, value);
        }
        
        public static readonly DependencyProperty ShowDetailsProperty =
            DependencyProperty.Register(nameof(ShowDetails), typeof(bool), 
                typeof(GranularThreatScoreCard), new PropertyMetadata(false));
        
        public GranularThreatScoreCard()
        {
            this.InitializeComponent();
        }
        
        private static void OnResultChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            var control = (GranularThreatScoreCard)d;
            if (e.NewValue is ThreatInferenceResult result)
            {
                control.UpdateUI(result);
            }
        }
        
        private void UpdateUI(ThreatInferenceResult result)
        {
            var score = result.GranularScores.CompositeScore;
            var level = result.ThreatLevel;
            
            // Update threat level text
            ThreatLevelText.Text = level.DisplayName;
            ThreatLevelText.Foreground = GetThreatLevelBrush(level);
            
            // Update score text
            ScoreText.Text = $"Score: {score:F2}/100";
            
            // Update progress ring and score value
            ProgressRing.Value = score;
            ScoreValueText.Text = $"{score:F2}";
            ScoreValueText.Foreground = GetThreatLevelBrush(level);
            
            // Update trend indicator
            if (result.GranularScores.ScoreDelta.HasValue)
            {
                var delta = result.GranularScores.ScoreDelta.Value;
                TrendPanel.Visibility = Visibility.Visible;
                
                if (delta > 0)
                {
                    TrendIcon.Text = "↑";
                    TrendIcon.Foreground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 255, 59, 48)); // Red
                    TrendText.Text = $"{Math.Abs(delta):F2} from last assessment";
                }
                else if (delta < 0)
                {
                    TrendIcon.Text = "↓";
                    TrendIcon.Foreground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 52, 199, 89)); // Green
                    TrendText.Text = $"{Math.Abs(delta):F2} from last assessment";
                }
                else
                {
                    TrendIcon.Text = "→";
                    TrendIcon.Foreground = new SolidColorBrush(Windows.UI.Color.FromArgb(255, 142, 142, 147)); // Gray
                    TrendText.Text = "No change from last assessment";
                }
            }
            else
            {
                TrendPanel.Visibility = Visibility.Collapsed;
            }
            
            // Update details toggle
            DetailsToggleButton.Content = ShowDetails ? "Hide Details" : "Show Details";
        }
        
        private void DetailsToggleButton_Click(object sender, RoutedEventArgs e)
        {
            ShowDetails = !ShowDetails;
            DetailsToggleButton.Content = ShowDetails ? "Hide Details" : "Show Details";
        }
        
        private Brush GetThreatLevelBrush(GranularThreatLevel level)
        {
            return new SolidColorBrush(GetThreatLevelColor(level));
        }
        
        private Windows.UI.Color GetThreatLevelColor(GranularThreatLevel level)
        {
            return level.NumericValue switch
            {
                >= 9 => Windows.UI.Color.FromArgb(255, 255, 59, 48),   // Critical/Extreme - Red
                >= 7 => Windows.UI.Color.FromArgb(255, 255, 149, 0),   // High/High-Critical - Orange
                >= 5 => Windows.UI.Color.FromArgb(255, 255, 204, 0),   // Medium/Medium-High - Yellow
                >= 3 => Windows.UI.Color.FromArgb(255, 255, 241, 0),   // Low/Low-Medium - Light Yellow
                _ => Windows.UI.Color.FromArgb(255, 52, 199, 89)       // Minimal/Very Low - Green
            };
        }
    }
}

