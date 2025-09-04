/// StatsScreen - Comprehensive meditation statistics and analytics
/// 
/// Advanced statistics dashboard with charts, calendar view, practice analytics,
/// and data export. Matches and exceeds PWA statistics functionality.

library;

// Dart imports
import 'dart:convert';
import 'dart:io';

// Package imports
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Local imports
import '../models/practice_config.dart';
import '../services/database_service.dart';
import '../services/statistics_service.dart';
import '../ui/layout.dart';
import '../ui/tokens.dart';
import '../utils/constants.dart';
import '../widgets/app_button.dart';
import '../widgets/section.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final StatisticsService _statisticsService = StatisticsService();
  StatsPeriod _selectedPeriod = StatsPeriod.week;
  StatisticsData? _currentStats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  // Public method to refresh stats from outside (e.g., on tab switch)
  void refresh() {
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _loading = true);
    // Always request a fresh calculation to avoid stale cache after new sessions
    final statsResult = await _statisticsService.getStatistics(_selectedPeriod, forceRefresh: true);
    if (mounted) {
      setState(() {
        _currentStats = statsResult.data;
        _loading = false;
      });
      
      if (statsResult.isFailure) {
        debugPrint('Failed to load statistics: ${statsResult.error}');
      }
    }
  }

  void _changePeriod(StatsPeriod period) {
    if (_selectedPeriod != period) {
      setState(() => _selectedPeriod = period);
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: AppScaffoldBody(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _currentStats == null
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadStatistics,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Period selection
                          _buildPeriodSelector(),
                          const SizedBox(height: UIConstants.buttonSpacing),
                          
                          // Summary cards
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          
                          // Practice calendar
                          _buildCalendarSection(),
                          const SizedBox(height: 24),
                          
                          // Charts section
                          _buildChartsSection(),
                          
                          const SizedBox(height: 24),
                          
                          // Data management section - PWA style
                          _buildDataControlsSection(),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Section(
      child: Row(
        children: [
          _buildPeriodButton('Week', StatsPeriod.week),
          _buildPeriodButton('Fortnight', StatsPeriod.fortnight),
          _buildPeriodButton('Month', StatsPeriod.month),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, StatsPeriod period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: UIConstants.periodButtonHeight,
          child: AppButton(
            label,
            onPressed: () => _changePeriod(period),
            variant: isSelected ? AppButtonVariant.secondary : AppButtonVariant.outline,
            size: AppButtonSize.sm,
            fullWidth: true,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Section(
      title: 'Statistics',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Spacing.s16),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Color(0xFF8B8B8B)),
              SizedBox(height: Spacing.s16),
              Text('No Statistics Available', style: TextStyle(fontSize: TypographyConstants.fontSizeLarge, fontWeight: TypographyConstants.fontWeightMedium, color: Color(0xFFB0B0B0))),
              SizedBox(height: Spacing.s8),
              Text('Complete some meditation sessions to see statistics', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: TypographyConstants.fontSizeBase), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = _currentStats!;
    Widget metric(IconData icon, String value, String label, Color color) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: Spacing.s8),
            Text(
              value,
              style: const TextStyle(
                fontSize: TypographyConstants.fontSizeMedium,
                fontWeight: TypographyConstants.fontWeightBold,
                color: Color(0xFFe5e5e5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: TypographyConstants.captionTextSize,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Section(
      title: 'Summary',
      child: Row(
        children: [
          metric(Icons.timer, stats.totalSessions.toString(), 'Sessions', const Color(0xFF20b2aa)),
          const SizedBox(width: 12),
          metric(Icons.access_time, '${stats.totalMinutes}m', 'Total Time', const Color(0xFF10b981)),
          const SizedBox(width: 12),
          metric(Icons.trending_up, '${stats.averageMinutes.round()}m', 'Average', const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }


  Widget _buildCalendarSection() {
    final stats = _currentStats!;
    final weekdayLabels = const ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Monday-first
    return Section(
      title: 'Practice Calendar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 2.0, right: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: weekdayLabels
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Padding(padding: const EdgeInsets.all(4), child: _buildCalendarGrid(stats)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(StatisticsData stats) {
    final todayDT = DateTime.now();
    final today = DateTime(todayDT.year, todayDT.month, todayDT.day);
    final weeks = _selectedPeriod == StatsPeriod.week
        ? 1
        : _selectedPeriod == StatsPeriod.fortnight
            ? 2
            : 4; // month -> 4 aligned weeks
    final daysToShow = _getAlignedDays(weeks: weeks, firstWeekday: DateTime.monday);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: daysToShow.length,
      itemBuilder: (context, index) {
        final date = daysToShow[index];
        final minutes = stats.dailyMinutes[date] ?? 0;
        final hasSession = minutes > 0;
        final isToday = date == today;
        final isFuture = date.isAfter(today);
        
        return Container(
          decoration: BoxDecoration(
            color: hasSession
                ? Color.fromARGB((255 * (0.22 + (minutes / 120).clamp(0.0, 0.6))).round(), 32, 178, 170)
                : Color.fromARGB((255 * (isFuture ? 0.05 : 0.1)).round(), 158, 158, 158),
            borderRadius: BorderRadius.circular(4),
            border: isToday ? Border.all(color: const Color(0xFF20b2aa), width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasSession ? Colors.white : (isFuture ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
              Text(
                minutes > 0 ? '${minutes}m' : '',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFFB0B0B0),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<DateTime> _getAlignedDays({int weeks = StatisticsConstants.calendarDaysToShow ~/ StatisticsConstants.weekDays, int firstWeekday = DateTime.monday}) {
    final nowDT = DateTime.now();
    final today = DateTime(nowDT.year, nowDT.month, nowDT.day);
    // Find start of current week based on firstWeekday
    final deltaToWeekStart = (today.weekday - firstWeekday + 7) % 7;
    final startOfCurrentWeek = today.subtract(Duration(days: deltaToWeekStart));
    // Start of window is (weeks-1) weeks before current week
    final startOfWindow = startOfCurrentWeek.subtract(Duration(days: StatisticsConstants.weekDays * (weeks - 1)));

    return List<DateTime>.generate(weeks * StatisticsConstants.weekDays, (i) {
      final d = startOfWindow.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  Widget _buildChartsSection() {
    final stats = _currentStats!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Section(
          title: 'Practice Distribution',
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _buildPracticeDistributionChart(stats),
          ),
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Practice Category Trends',
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _buildCategoryDistributionChart(stats),
          ),
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Posture Distribution',
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _buildPostureChart(stats),
          ),
        ),
        const SizedBox(height: 16),
        Section(
          title: 'Average Duration',
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _buildAverageDurationChart(stats),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPracticeDistributionChart(StatisticsData stats) {
    final entries = stats.practiceDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const Center(child: Text('No practice data available', style: TextStyle(color: Colors.grey)));
    }

    final total = entries.fold<int>(0, (sum, e) => sum + e.value);
    final top = entries.take(8).toList();

    return Column(
      children: top.map((e) {
        final percent = total > 0 ? (e.value / total) : 0.0;
        final cat = PracticeConfig.getCategoryForPractice(e.key);
        final color = PracticeConfig.getCategoryColor(cat);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(percent * 100).round()}%', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: Theme.of(context).extension<SemanticColors>()!.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryDistributionChart(StatisticsData stats) {
    // Line chart showing practice counts per category per day (like PWA)
    final sessions = stats.sessions;
    final dates = <DateTime>[];
    for (DateTime d = stats.startDate; !d.isAfter(stats.endDate); d = d.add(const Duration(days: 1))) {
      final day = DateTime(d.year, d.month, d.day);
      dates.add(day);
    }

    final categories = PracticeConfig.getAllCategories();
    // Count NUMBER of practices per category per day (not minutes)
    final Map<DateTime, Map<String, int>> dayCategoryCounts = {
      for (final d in dates) d: {for (final c in categories) c: 0}
    };
    
    for (final session in sessions) {
      final day = DateTime(session.date.year, session.date.month, session.date.day);
      if (!dayCategoryCounts.containsKey(day)) continue;
      
      if (session.practices.isEmpty) {
        dayCategoryCounts[day]!['general'] = (dayCategoryCounts[day]!['general'] ?? 0) + 1;
      } else {
        for (final practice in session.practices) {
          dayCategoryCounts[day]![practice.category] = (dayCategoryCounts[day]![practice.category] ?? 0) + 1;
        }
      }
    }

    // Create line datasets for each category
    final lineDatasets = <LineChartBarData>[];
    double maxY = 1.0;
    
    for (final category in categories) {
      final spots = <FlSpot>[];
      for (int i = 0; i < dates.length; i++) {
        final count = dayCategoryCounts[dates[i]]![category]!.toDouble();
        spots.add(FlSpot(i.toDouble(), count));
        if (count > maxY) maxY = count;
      }
      
      // Only add line if category has any data
      if (spots.any((spot) => spot.y > 0)) {
        lineDatasets.add(
          LineChartBarData(
            spots: spots,
            color: PracticeConfig.getCategoryColor(category),
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    final labelStep = (dates.length / 7).ceil().clamp(1, 7);
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          maxY: maxY + 1, // Add padding above highest point
          minY: 0,
          lineBarsData: lineDatasets,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, m) {
                  final count = v.toInt();
                  if (count < 0 || v != count.toDouble()) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text('$count', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  final idx = v.round();
                  if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                  if (idx % labelStep != 0) return const SizedBox.shrink();
                  final d = dates[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('${d.day}', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxY > 10 ? 5 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).extension<SemanticColors>()!.border.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).extension<SemanticColors>()!.border.withOpacity(0.5)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final categoryIndex = touchedSpot.barIndex;
                  final category = categories[categoryIndex];
                  return LineTooltipItem(
                    '$category\n${touchedSpot.y.toInt()} practices',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostureChart(StatisticsData stats) {
    if (stats.postureDistribution.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No posture data available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final colors = [
      Theme.of(context).colorScheme.primary,       // 0xFF20b2aa
      Theme.of(context).extension<SemanticColors>()!.success, // 0xFF10b981  
      Theme.of(context).extension<SemanticColors>()!.warning, // 0xFFF59E0B
      const Color(0xFF8B5CF6),                     // Purple accent
    ];

    final sections = stats.postureDistribution.entries
        .toList()
        .asMap()
        .entries
        .map((entry) {
      return PieChartSectionData(
        value: entry.value.value.toDouble(),
        title: '${entry.value.value}',
        color: colors[entry.key % colors.length],
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 3,
                centerSpaceRadius: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: stats.postureDistribution.entries
                .toList()
                .asMap()
                .entries
                .map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[entry.key % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.value.key,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageDurationChart(StatisticsData stats) {
    // Line chart showing average session duration per day (like PWA)
    final dates = <DateTime>[];
    for (DateTime d = stats.startDate; !d.isAfter(stats.endDate); d = d.add(const Duration(days: 1))) {
      final day = DateTime(d.year, d.month, d.day);
      dates.add(day);
    }

    // Calculate average duration per day using existing data
    final spots = <FlSpot>[];
    double maxY = 1.0;
    
    for (int i = 0; i < dates.length; i++) {
      final day = dates[i];
      final totalMinutes = stats.dailyMinutes[day] ?? 0;
      final sessionCount = stats.dailySessions[day] ?? 0;
      final avgDuration = sessionCount > 0 ? totalMinutes / sessionCount : 0.0;
      
      spots.add(FlSpot(i.toDouble(), avgDuration));
      if (avgDuration > maxY) maxY = avgDuration;
    }

    final labelStep = (dates.length / 7).ceil().clamp(1, 7);
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          maxY: maxY + 5, // Add padding above highest point
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              color: Theme.of(context).colorScheme.secondary, // Use app's secondary color
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (v, m) {
                  final minutes = v.toInt();
                  if (minutes < 0 || v != minutes.toDouble()) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text('${minutes}m', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  final idx = v.round();
                  if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                  if (idx % labelStep != 0) return const SizedBox.shrink();
                  final d = dates[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('${d.day}', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: maxY > 30 ? 10 : 5,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).extension<SemanticColors>()!.border.withOpacity(0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).extension<SemanticColors>()!.border.withOpacity(0.5)),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  return LineTooltipItem(
                    'Average Duration\n${touchedSpot.y.toInt()} minutes',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final data = await _statisticsService.exportStatistics(_selectedPeriod);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'bptimer_export_${DateTime.now().millisecondsSinceEpoch}.json'));
      await file.writeAsString(jsonString);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported: ${file.path}'), backgroundColor: const Color(0xFF20b2aa)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final content = utf8.decode(bytes);
      final Map<String, dynamic> data = json.decode(content) as Map<String, dynamic>;
      await DatabaseService().importData(data);
      await _loadStatistics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported'), backgroundColor: Color(0xFF20b2aa)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetData() async {
    try {
      await DatabaseService().clearAllData();
      await _loadStatistics();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared'), backgroundColor: Color(0xFF20b2aa)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Build data controls section matching PWA
  Widget _buildDataControlsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: const TextStyle(
                fontSize: TypographyConstants.fontSizeLarge,
                fontWeight: TypographyConstants.fontWeightSemiBold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Export Data button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _currentStats != null ? _exportData : null,
                icon: const Icon(Icons.file_download),
                label: const Text(
                  'Export Data',
                  style: TextStyle(
                    fontSize: TypographyConstants.fontSizeBase,
                    fontWeight: TypographyConstants.fontWeightMedium,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF20b2aa),
                  side: const BorderSide(color: Color(0xFF20b2aa)),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Import Data button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _importData,
                icon: const Icon(Icons.file_upload),
                label: const Text(
                  'Import Data',
                  style: TextStyle(
                    fontSize: TypographyConstants.fontSizeBase,
                    fontWeight: TypographyConstants.fontWeightMedium,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF20b2aa),
                  side: const BorderSide(color: Color(0xFF20b2aa)),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Reset All Data button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _resetData,
                icon: const Icon(Icons.warning_outlined),
                label: const Text(
                  'Reset All Data',
                  style: TextStyle(
                    fontSize: TypographyConstants.fontSizeBase,
                    fontWeight: TypographyConstants.fontWeightMedium,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
