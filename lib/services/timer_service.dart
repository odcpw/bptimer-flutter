/// TimerService - Core meditation timer functionality with state management
/// 
/// Manages timer state, background execution, and session completion.
/// Uses result-based error handling and ChangeNotifier for reactive UI updates.
/// Designed to work seamlessly with the Flutter app lifecycle.

library;

// Dart imports
import 'dart:async';

// Package imports
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

// Local imports
import '../models/practice.dart';
import '../utils/constants.dart';
import '../utils/result.dart';
import 'notification_service.dart';

enum TimerState {
  stopped,
  running,
  paused,
  completed,
}

class TimerService extends ChangeNotifier with WidgetsBindingObserver {
  // Timer state
  Timer? _timer;
  TimerState _state = TimerState.stopped;
  int _elapsed = 0; // seconds elapsed
  int _duration = TimerConstants.defaultDurationSeconds;
  
  // Session data
  List<Practice> _selectedPractices = [];
  String? _selectedPosture;
  String? _sessionNotes;
  
  // Audio player for bell sound
  AudioPlayer? _audioPlayer;
  
  // Services
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Background timer tracking
  DateTime? _sessionStartTime;
  DateTime? _backgroundEnterTime;
  bool _wasRunningWhenBackgrounded = false;
  
  // Notification constants
  static const int _timerNotificationId = 999; // Unique ID for timer notifications
  
  TimerService() {
    WidgetsBinding.instance.addObserver(this);
  }

  // Getters
  TimerState get state => _state;
  int get elapsed => _elapsed;
  int get duration => _duration;
  int get remaining => _duration - _elapsed;
  double get progress => _duration > 0 ? _elapsed / _duration : 0.0;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isStopped => _state == TimerState.stopped;
  bool get isCompleted => _state == TimerState.completed;
  List<Practice> get selectedPractices => List.unmodifiable(_selectedPractices);
  String? get selectedPosture => _selectedPosture;
  String? get sessionNotes => _sessionNotes;

  /// Format time in MM:SS format
  String get formattedElapsed => _formatTime(_elapsed);
  String get formattedRemaining => _formatTime(remaining);
  String get formattedDuration => _formatTime(_duration);

  /// Start the meditation timer
  Future<SimpleResult> start() async {
    if (_state == TimerState.running) {
      return const Failure(TimerError.alreadyRunning);
    }
    
    _state = TimerState.running;
    _sessionStartTime = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: TimerConstants.timerTickIntervalMs), _tick);
    
    // Request wake lock to keep screen on
    await _requestWakeLock();
    
    // Schedule completion notification for background timer
    await _scheduleCompletionNotification();
    
    notifyListeners();
    debugPrint('[Timer] Started: duration=${_duration}s, practices=${_selectedPractices.length}');
    return const Success(true);
  }

  /// Pause the meditation timer
  Future<void> pause() async {
    if (_state != TimerState.running) return;
    
    _timer?.cancel();
    _state = TimerState.paused;
    
    // Release wake lock
    await _releaseWakeLock();
    
    notifyListeners();
    debugPrint('[Timer] Paused at: ${_elapsed}s of ${_duration}s');
  }

  /// Resume the meditation timer
  Future<void> resume() async {
    if (_state != TimerState.paused) return;
    
    _state = TimerState.running;
    _timer = Timer.periodic(const Duration(milliseconds: TimerConstants.timerTickIntervalMs), _tick);
    
    // Request wake lock again
    await _requestWakeLock();
    
    notifyListeners();
    debugPrint('[Timer] Resumed from: ${_elapsed}s');
  }

  /// Stop the meditation timer and reset
  Future<void> stop() async {
    _timer?.cancel();
    await _releaseWakeLock();
    await _cancelTimerNotification();
    await stopBellSound(); // Stop any playing bell sound
    
    final wasRunning = _state == TimerState.running || _state == TimerState.paused;
    
    _state = TimerState.stopped;
    _elapsed = 0;
    _sessionStartTime = null;
    _backgroundEnterTime = null;
    _wasRunningWhenBackgrounded = false;
    
    notifyListeners();
    debugPrint('[Timer] Stopped${wasRunning ? ' (session not saved)' : ''}');
  }

  /// Reset timer to initial state
  Future<void> reset() async {
    await stop();
    _elapsed = 0;
    _selectedPractices.clear();
    _selectedPosture = null;
    _sessionNotes = null;
    notifyListeners();
  }

  /// Set timer duration in seconds
  SimpleResult setDuration(int seconds) {
    if (_state == TimerState.running) {
      return const Failure(TimerError.alreadyRunning);
    }
    
    if (seconds < TimerConstants.minDurationSeconds || seconds > TimerConstants.maxDurationSeconds) {
      return const Failure(TimerError.invalidDuration);
    }
    
    _duration = seconds;
    if (_elapsed > _duration) {
      _elapsed = _duration;
    }
    debugPrint('[Timer] Duration set: ${seconds}s');
    notifyListeners();
    return const Success(true);
  }

  /// Increase duration by 5 minutes
  SimpleResult increaseDuration() {
    return setDuration(_duration + TimerConstants.durationIncrementSeconds);
  }

  /// Decrease duration by 5 minutes
  SimpleResult decreaseDuration() {
    return setDuration(_duration - TimerConstants.durationIncrementSeconds);
  }

  /// Set selected practices for this session
  void setSelectedPractices(List<Practice> practices) {
    _selectedPractices = List.from(practices);
    notifyListeners();
  }

  /// Add a practice to the session
  void addPractice(Practice practice) {
    if (!_selectedPractices.any((p) => p.name == practice.name)) {
      _selectedPractices.add(practice);
      debugPrint('[Timer] Practice added: ${practice.name} from ${practice.category}');
      notifyListeners();
    }
  }

  /// Remove a practice from the session
  void removePractice(Practice practice) {
    _selectedPractices.removeWhere((p) => p.name == practice.name);
    debugPrint('[Timer] Practice removed: ${practice.name}');
    notifyListeners();
  }

  /// Clear all selected practices
  void clearPractices() {
    _selectedPractices.clear();
    notifyListeners();
  }

  /// Reorder selected practices
  void reorderPractices(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final Practice practice = _selectedPractices.removeAt(oldIndex);
    _selectedPractices.insert(newIndex, practice);
    notifyListeners();
  }

  /// Set meditation posture
  void setPosture(String? posture) {
    _selectedPosture = posture;
    debugPrint('[Timer] Posture selected: ${posture ?? "none"}');
    notifyListeners();
  }

  /// Set session notes
  void setNotes(String? notes) {
    _sessionNotes = notes?.isNotEmpty == true ? notes : null;
    notifyListeners();
  }

  /// Timer tick handler
  void _tick(Timer timer) {
    _elapsed++;
    
    // Update UI first, then check completion
    notifyListeners();
    
    // Check if timer is complete (allow display of 00:00)
    if (_elapsed >= _duration) {
      _completeSession();
    }
  }

  /// Complete the meditation session
  Future<void> _completeSession() async {
    _timer?.cancel();
    await _releaseWakeLock();
    await _cancelTimerNotification(); // Cancel since we completed naturally
    
    _state = TimerState.completed;
    
    // Clear background tracking
    _sessionStartTime = null;
    _backgroundEnterTime = null;
    _wasRunningWhenBackgrounded = false;
    
    // Session will be saved only when user chooses to record it
    // This prevents duplicate saves when user interacts with completion screen
    
    // Play completion sound or haptic feedback
    await _triggerCompletion();
    
    notifyListeners();
    debugPrint('[Timer] Completed: ${_elapsed}s, practices=${_selectedPractices.length} (session not auto-saved)');
  }


  /// Trigger completion feedback
  Future<void> _triggerCompletion() async {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Play meditation bell sound (non-blocking)
    _audioPlayer ??= AudioPlayer();
    _playBellSound(); // No await - let it play in background
    debugPrint('[Timer] Bell sound started (playing in background)');
  }
  
  /// Play bell sound for completion (async, non-blocking)
  Future<VoidResult> _playBellSound() async {
    try {
      await _audioPlayer!.setAsset('assets/sounds/bell.mp3');
      await _audioPlayer!.play();
      debugPrint('[Timer] Bell sound playback started');
      return const Success(null);
    } catch (e) {
      debugPrint('[ERROR][Timer] Bell sound playback failed: $e');
      return const Failure('Bell playback failed');
    }
  }
  
  /// Stop bell sound playback
  Future<void> stopBellSound() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        debugPrint('[Timer] Bell sound stopped');
      }
    } catch (e) {
      debugPrint('[ERROR][Timer] Failed to stop bell sound: $e');
    }
  }

  /// Request wake lock to keep screen on during meditation
  /// Note: Native Android FLAG_KEEP_SCREEN_ON is set in MainActivity.kt as primary solution
  Future<void> _requestWakeLock() async {
    try {
      await WakelockPlus.enable();
      debugPrint('[Timer] Wake lock enabled (wakelock_plus + native FLAG_KEEP_SCREEN_ON) - screen will stay on');
    } catch (e) {
      debugPrint('[ERROR][Timer] Failed to enable wake lock: $e (native flag should still work)');
    }
  }

  /// Release wake lock
  /// Note: Native Android FLAG_KEEP_SCREEN_ON remains active until app closes
  Future<void> _releaseWakeLock() async {
    try {
      await WakelockPlus.disable();
      debugPrint('[Timer] Wake lock disabled (wakelock_plus) - native flag keeps screen on until app closes');
    } catch (e) {
      debugPrint('[ERROR][Timer] Failed to disable wake lock: $e (native flag should still work)');
    }
  }
  
  /// Schedule completion notification for background timer
  Future<void> _scheduleCompletionNotification() async {
    if (_sessionStartTime == null) return;
    
    try {
      // Initialize notifications if not already done
      await _notificationService.initialize();
      
      if (!_notificationService.areNotificationsEnabled) {
        debugPrint('[Timer] Notifications not enabled, skipping timer notification');
        return;
      }
      
      // Calculate completion time
      final completionTime = _sessionStartTime!.add(Duration(seconds: _duration));
      final practiceNames = _selectedPractices.map((p) => p.name).join(', ');
      final title = 'Meditation Complete';
      final body = practiceNames.isNotEmpty 
          ? 'Your ${_formatTime(_duration)} session is complete: $practiceNames'
          : 'Your ${_formatTime(_duration)} meditation session is complete';
      
      // Cancel any existing timer notification
      await _cancelTimerNotification();
      
      // Schedule new notification
      await _localNotifications.zonedSchedule(
        _timerNotificationId,
        title,
        body,
        tz.TZDateTime.from(completionTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'timer_channel',
            'Timer Notifications',
            channelDescription: 'Notifications for meditation timer completion',
            importance: Importance.high,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound('bell'),
          ),
          iOS: DarwinNotificationDetails(
            sound: 'bell.mp3',
          ),
        ),
        payload: 'timer_complete',
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint('[Timer] Scheduled completion notification for ${completionTime.toString()}');
    } catch (e) {
      debugPrint('[ERROR][Timer] Failed to schedule completion notification: $e');
    }
  }
  
  /// Cancel timer completion notification
  Future<void> _cancelTimerNotification() async {
    try {
      await _localNotifications.cancel(_timerNotificationId);
      debugPrint('[Timer] Cancelled timer notification');
    } catch (e) {
      debugPrint('[ERROR][Timer] Failed to cancel timer notification: $e');
    }
  }

  /// Format seconds to MM:SS string
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Get practice summary for current session
  String getPracticeSummary() {
    if (_selectedPractices.isEmpty) return 'Meditation';
    if (_selectedPractices.length == 1) return _selectedPractices.first.name;
    if (_selectedPractices.length <= 3) {
      return _selectedPractices.map((p) => p.name).join(', ');
    }
    return '${_selectedPractices.first.name} and ${_selectedPractices.length - 1} others';
  }

  /// Check if session has enough data to be meaningful
  bool get hasValidSession => _selectedPractices.isNotEmpty || _elapsed >= 60;

  /// Get session completion percentage
  double get completionPercentage => _duration > 0 ? (_elapsed / _duration * 100).clamp(0.0, 100.0) : 0.0;

  /// Get estimated remaining time
  Duration get estimatedTimeRemaining => Duration(seconds: remaining.clamp(0, _duration));

  /// Manual completion (for when user wants to end early but save session)
  Future<SimpleResult> completeEarly() async {
    if (_state != TimerState.running && _state != TimerState.paused) {
      return const Failure(TimerError.notRunning);
    }
    
    if (_elapsed < TimerConstants.minSessionSaveSeconds) {
      debugPrint('Session too short to save (${_elapsed}s)');
      stop();
      return const Failure(TimerError.sessionTooShort);
    }

    _timer?.cancel();
    await _releaseWakeLock();
    await _cancelTimerNotification();
    
    _state = TimerState.completed;
    
    // Clear background tracking
    _sessionStartTime = null;
    _backgroundEnterTime = null;
    _wasRunningWhenBackgrounded = false;
    
    // Session will be saved only when user chooses to record it
    // This prevents duplicate saves when user interacts with completion screen
    
    // Lighter feedback for early completion
    HapticFeedback.selectionClick();
    
    notifyListeners();
    debugPrint('[Timer] Session completed early: ${_elapsed}s (session not auto-saved)');
    return const Success(true);
  }

  /// Toggle between pause and resume
  Future<void> togglePauseResume() async {
    if (_state == TimerState.running) {
      await pause();
    } else if (_state == TimerState.paused) {
      await resume();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _onAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.detached:
        // App is about to be terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        _onAppBackgrounded();
        break;
    }
  }
  
  /// Handle app going to background
  void _onAppBackgrounded() {
    _backgroundEnterTime = DateTime.now();
    _wasRunningWhenBackgrounded = _state == TimerState.running;
    debugPrint('[Timer] App backgrounded - timer state: $_state');
  }
  
  /// Handle app returning from background
  void _onAppResumed() {
    if (_backgroundEnterTime != null && _wasRunningWhenBackgrounded) {
      _syncTimerFromBackground();
    }
    _backgroundEnterTime = null;
    _wasRunningWhenBackgrounded = false;
    debugPrint('[Timer] App resumed - timer state: $_state');
  }
  
  /// Synchronize timer state after returning from background
  void _syncTimerFromBackground() {
    if (_sessionStartTime == null || _backgroundEnterTime == null) return;
    
    final now = DateTime.now();
    final totalElapsedInBackground = now.difference(_sessionStartTime!).inSeconds;
    
    // Update elapsed time based on real time passed
    final previousElapsed = _elapsed;
    _elapsed = totalElapsedInBackground;
    
    final timeDrift = (_elapsed - previousElapsed).abs();
    if (timeDrift > 2) { // Only log significant drift
      debugPrint('[Timer] Corrected timer drift: ${timeDrift}s (was ${previousElapsed}s, now ${_elapsed}s)');
    }
    
    // Check if timer should be completed
    if (_elapsed >= _duration && _state == TimerState.running) {
      debugPrint('[Timer] Timer completed while in background');
      _completeSession();
    } else if (_state == TimerState.running) {
      // Timer is still running, update UI
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _releaseWakeLock(); // Fire and forget for disposal
    super.dispose();
  }
}
