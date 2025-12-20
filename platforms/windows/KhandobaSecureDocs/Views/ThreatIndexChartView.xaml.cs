using Microsoft.UI.Xaml.Controls;
using LiveChartsCore;
using LiveChartsCore.SkiaSharpView;
using LiveChartsCore.SkiaSharpView.Painting;
using SkiaSharp;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Globalization;
using System.Linq;

namespace KhandobaSecureDocs.Views
{
    public class ThreatIndexDataPoint
    {
        public DateTime Timestamp { get; set; }
        public double ThreatIndex { get; set; }
        public string ThreatLevel { get; set; } = "low"; // "low", "medium", "high", "critical"
    }

    public sealed partial class ThreatIndexChartView : UserControl
    {
        private ObservableCollection<ISeries> _series = new();
        private List<ThreatIndexDataPoint> _threatIndexHistory = new();
        private double? _currentThreatIndex;

        public ObservableCollection<ISeries> Series
        {
            get => _series;
            private set
            {
                _series = value;
            }
        }

        public ThreatIndexChartView()
        {
            InitializeComponent();
        }

        public void UpdateThreatIndexData(List<ThreatIndexDataPoint> history, double? currentIndex = null)
        {
            _threatIndexHistory = history;
            _currentThreatIndex = currentIndex;

            if (history.Count == 0)
            {
                EmptyStatePanel.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
                ThreatChart.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
                ThreatIndexBadge.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
                return;
            }

            EmptyStatePanel.Visibility = Microsoft.UI.Xaml.Visibility.Collapsed;
            ThreatChart.Visibility = Microsoft.UI.Xaml.Visibility.Visible;
            ThreatIndexBadge.Visibility = Microsoft.UI.Xaml.Visibility.Visible;

            // Create line series
            var lineSeries = new LineSeries<double>
            {
                Values = history.Select(d => d.ThreatIndex).ToArray(),
                Stroke = new SolidColorPaint(GetThreatColor(history.LastOrDefault()?.ThreatLevel ?? "low")),
                Fill = null,
                GeometrySize = 4,
                LineSmoothness = 0.2
            };

            _series.Clear();
            _series.Add(lineSeries);

            // Update threat index badge
            if (currentIndex.HasValue)
            {
                ThreatIndexValue.Text = currentIndex.Value.ToString("F0");
                ThreatLevelText.Text = GetThreatLevel(currentIndex.Value).ToUpper();
                
                var badgeColor = GetThreatColor(GetThreatLevel(currentIndex.Value));
                ThreatIndexBadge.Background = new Microsoft.UI.Xaml.Media.SolidColorBrush(
                    Microsoft.UI.Color.FromArgb(255, badgeColor.Red, badgeColor.Green, badgeColor.Blue)
                );
            }
        }

        private string GetThreatLevel(double index)
        {
            if (index >= 75) return "critical";
            if (index >= 50) return "high";
            if (index >= 25) return "medium";
            return "low";
        }

        private SKColor GetThreatColor(string level)
        {
            return level.ToLower() switch
            {
                "critical" => SKColors.Red,
                "high" => new SKColor(0xFF, 0x98, 0x00), // Orange
                "medium" => SKColors.Yellow,
                _ => SKColors.Green
            };
        }

        private string XAxisFormatter(DateTime dateTime)
        {
            return dateTime.ToString("MM/dd", CultureInfo.InvariantCulture);
        }
    }
}
