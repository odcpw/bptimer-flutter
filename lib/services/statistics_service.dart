/// StatisticsService - Advanced meditation analytics and data aggregation
/// 
/// Calculates comprehensive statistics from meditation sessions including
/// time-based analytics, practice distributions, trends, and calendar data.
/// Uses result-based error handling for database operations.

library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/practice_config.dart';
import '../services/database_service.dart';
import '../utils/result.dart';
import '../utils/constants.dart';

enum StatsPeriod { week, fortnight, month, quarter, year, allTime }

class StatisticsData {
  final List<Session> sessions;
  final int totalSessions;
  final int totalMinutes;
  final double averageMinutes;
  final Map<String, int> practiceDistribution;
  final Map<String, int> categoryDistribution;
  final Map<String, int> postureDistribution;
  final Map<DateTime, int> dailyMinutes;
  final Map<DateTime, int> dailySessions;
  final List<DurationTrendPoint> durationTrend;
  final DateTime startDate;
  final DateTime endDate;
  final StatsPeriod period;

  const StatisticsData({
    required this.sessions,
    required this.totalSessions,
    required this.totalMinutes,
    required this.averageMinutes,
    required this.practiceDistribution,
    required this.categoryDistribution,
    required this.postureDistribution,
    required this.dailyMinutes,
    required this.dailySessions,
    required this.durationTrend,
    required this.startDate,
    required this.endDate,
    required this.period,
  });
}

class DurationTrendPoint {
  final DateTime date;
  final double averageMinutes;
  final int sessionCount;

  const DurationTrendPoint({
    required this.date,
    required this.averageMinutes,
    required this.sessionCount,
  });
}

class StatisticsService extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  // Cache
  StatisticsData? _cachedStats;
  // Default to week view to match UI expectation
  StatsPeriod _currentPeriod = StatsPeriod.week;
  DateTime? _cacheTimestamp;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  /// Get statistics for the specified period
  /// Set [forceRefresh] to true to bypass cache and calculate fresh stats
  Future<DatabaseResult<StatisticsData>> getStatistics(StatsPeriod period, {bool forceRefresh = false}) async {
    debugPrint('[Stats] Period requested: ${period.name}');
    
    // Check cache validity
    if (!forceRefresh &&
        _cachedStats != null && 
        _currentPeriod == period &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheTimeout) {
      debugPrint('[Stats] Using cached data');
      return Success(_cachedStats!);
    }

    // Calculate fresh statistics
    final dateRange = _getDateRangeForPeriod(period);
    final sessionsResult = await _databaseService.getSessionsForPeriod(
      dateRange.start, 
      dateRange.end,
    );
    
    if (sessionsResult.isFailure) {
      debugPrint('[ERROR][Stats] Failed to load sessions: ${sessionsResult.error}');
      return Failure(sessionsResult.error!);
    }

    debugPrint('[Stats] Sessions in period: ${sessionsResult.data!.length}');
    final stats = await _calculateStatistics(sessionsResult.data!, period, dateRange.start, dateRange.end);
    
    // Update cache
    _cachedStats = stats;
    _currentPeriod = period;
    _cacheTimestamp = DateTime.now();
    
    debugPrint('[Stats] Calculated: ${stats.totalSessions} sessions, ${stats.totalMinutes}min total');
    notifyListeners();
    return Success(stats);
  }

  /// Calculate comprehensive statistics from session data
  Future<StatisticsData> _calculateStatistics(
    List<Session> sessions,
    StatsPeriod period,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Basic aggregations
    final totalSessions = sessions.length;
    final totalMinutes = sessions.fold<int>(0, (sum, session) => sum + (session.duration ~/ 60));
    final averageMinutes = totalSessions > 0 ? totalMinutes / totalSessions : 0.0;

    // Practice distribution
    final practiceDistribution = <String, int>{};
    for (final session in sessions) {
      for (final practice in session.practices) {
        practiceDistribution[practice.name] = (practiceDistribution[practice.name] ?? 0) + 1;
      }
    }

    // Category distribution
    final categoryDistribution = <String, int>{};
    for (final session in sessions) {
      for (final practice in session.practices) {
        final category = practice.category;
        categoryDistribution[category] = (categoryDistribution[category] ?? 0) + 1;
      }
      // Count sessions without practices as "general"
      if (session.practices.isEmpty) {
        categoryDistribution['general'] = (categoryDistribution['general'] ?? 0) + 1;
      }
    }

    // Posture distribution
    final postureDistribution = <String, int>{};
    for (final session in sessions) {
      final posture = session.posture ?? 'Not specified';
      postureDistribution[posture] = (postureDistribution[posture] ?? 0) + 1;
    }

    // Daily aggregations
    final dailyMinutes = <DateTime, int>{};
    final dailySessions = <DateTime, int>{};
    
    for (final session in sessions) {
      final date = DateTime(session.date.year, session.date.month, session.date.day);
      dailyMinutes[date] = (dailyMinutes[date] ?? 0) + (session.duration ~/ 60);
      dailySessions[date] = (dailySessions[date] ?? 0) + 1;
    }

    // Duration trend (weekly averages for better visualization)
    final durationTrend = _calculateDurationTrend(sessions, startDate, endDate);

    return StatisticsData(
      sessions: sessions,
      totalSessions: totalSessions,
      totalMinutes: totalMinutes,
      averageMinutes: averageMinutes,
      practiceDistribution: practiceDistribution,
      categoryDistribution: categoryDistribution,
      postureDistribution: postureDistribution,
      dailyMinutes: dailyMinutes,
      dailySessions: dailySessions,
      durationTrend: durationTrend,
      startDate: startDate,
      endDate: endDate,
      period: period,
    );
  }

  /// Calculate duration trend with weekly aggregation
  List<DurationTrendPoint> _calculateDurationTrend(
    List<Session> sessions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final trendPoints = <DurationTrendPoint>[];
    final weeklyData = <DateTime, List<Session>>{};

    // Group sessions by week
    for (final session in sessions) {
      final weekStart = _getWeekStart(session.date);
      weeklyData[weekStart] = (weeklyData[weekStart] ?? [])..add(session);
    }

    // Calculate weekly averages
    final sortedWeeks = weeklyData.keys.toList()..sort();
    for (final weekStart in sortedWeeks) {
      final weekSessions = weeklyData[weekStart]!;
      final totalMinutes = weekSessions.fold<int>(0, (sum, session) => sum + (session.duration ~/ 60));
      final averageMinutes = totalMinutes / weekSessions.length;

      trendPoints.add(DurationTrendPoint(
        date: weekStart,
        averageMinutes: averageMinutes,
        sessionCount: weekSessions.length,
      ));
    }

    return trendPoints;
  }

  /// Get the start of the week (Monday) for a given date
  DateTime _getWeekStart(DateTime date) {
    final daysFromMonday = (date.weekday - 1) % 7;
    return DateTime(date.year, date.month, date.day - daysFromMonday);
  }

  /// Get date range for specified period
  ({DateTime start, DateTime end}) _getDateRangeForPeriod(StatsPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case StatsPeriod.week:
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        return (start: weekStart, end: now);
      
      case StatsPeriod.fortnight:
        final fortnightStart = today.subtract(const Duration(days: 14));
        return (start: fortnightStart, end: now);
      
      case StatsPeriod.month:
        final monthStart = DateTime(today.year, today.month - 1, today.day);
        return (start: monthStart, end: now);
      
      case StatsPeriod.quarter:
        final quarterStart = DateTime(today.year, today.month - 3, today.day);
        return (start: quarterStart, end: now);
      
      case StatsPeriod.year:
        final yearStart = DateTime(today.year - 1, today.month, today.day);
        return (start: yearStart, end: now);
      
      case StatsPeriod.allTime:
        // Use a very early date for all-time statistics
        return (start: DateTime(2020, 1, 1), end: now);
    }
  }

  /// Get human-readable period name
  String getPeriodName(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.week:
        return 'This Week';
      case StatsPeriod.fortnight:
        return 'Last 2 Weeks';
      case StatsPeriod.month:
        return 'Last Month';
      case StatsPeriod.quarter:
        return 'Last 3 Months';
      case StatsPeriod.year:
        return 'Last Year';
      case StatsPeriod.allTime:
        return 'All Time';
    }
  }

  /// Clear statistics cache
  void clearCache() {
    _cachedStats = null;
    _cacheTimestamp = null;
    notifyListeners();
  }

  /// Get category color for charts
  Color getCategoryColor(String category) {
    return PracticeConfig.getCategoryColor(category);
  }

  /// Get practice streaks (consecutive days of practice)
  Future<DatabaseResult<List<int>>> getStreaks(StatsPeriod period) async {
    final statsResult = await getStatistics(period);
    if (statsResult.isFailure) {
      return Failure(statsResult.error!);
    }
    
    final stats = statsResult.data!;
    final streaks = <int>[];
    
    final sortedDates = stats.dailySessions.keys.toList()..sort();
    if (sortedDates.isEmpty) return Success(streaks);

    int currentStreak = 1;
    DateTime previousDate = sortedDates.first;

    for (int i = 1; i < sortedDates.length; i++) {
      final currentDate = sortedDates[i];
      final daysDifference = currentDate.difference(previousDate).inDays;

      if (daysDifference == 1) {
        // Consecutive day
        currentStreak++;
      } else {
        // Streak broken
        streaks.add(currentStreak);
        currentStreak = 1;
      }
      
      previousDate = currentDate;
    }
    
    // Add the final streak
    streaks.add(currentStreak);
    
    return Success(streaks);
  }

  /// Get current streak
  Future<DatabaseResult<int>> getCurrentStreak() async {
    final today = DateTime.now();
    final sessionsResult = await _databaseService.getRecentSessions(StatisticsConstants.defaultPeriodDays); // Check last month
    
    if (sessionsResult.isFailure) {
      return Failure(sessionsResult.error!);
    }
    
    final sessions = sessionsResult.data!;
    if (sessions.isEmpty) return const Success(0);

    int streak = 0;
    DateTime checkDate = DateTime(today.year, today.month, today.day);

    while (true) {
      final dayHasSessions = sessions.any((session) {
        final sessionDate = DateTime(session.date.year, session.date.month, session.date.day);
        return sessionDate == checkDate;
      });

      if (dayHasSessions) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return Success(streak);
  }

  /// Export statistics data as JSON
  Future<DatabaseResult<Map<String, dynamic>>> exportStatistics(StatsPeriod period) async {
    final statsResult = await getStatistics(period);
    if (statsResult.isFailure) {
      return Failure(statsResult.error!);
    }
    
    final stats = statsResult.data!;
    final exportData = {
      'period': period.name,
      'startDate': stats.startDate.toIso8601String(),
      'endDate': stats.endDate.toIso8601String(),
      'totalSessions': stats.totalSessions,
      'totalMinutes': stats.totalMinutes,
      'averageMinutes': stats.averageMinutes,
      'practiceDistribution': stats.practiceDistribution,
      'categoryDistribution': stats.categoryDistribution,
      'postureDistribution': stats.postureDistribution,
      'dailyMinutes': stats.dailyMinutes.map((k, v) => MapEntry(k.toIso8601String(), v)),
      'dailySessions': stats.dailySessions.map((k, v) => MapEntry(k.toIso8601String(), v)),
      'durationTrend': stats.durationTrend.map((point) => {
        'date': point.date.toIso8601String(),
        'averageMinutes': point.averageMinutes,
        'sessionCount': point.sessionCount,
      }).toList(),
    };
    return Success(exportData);
  }
}
