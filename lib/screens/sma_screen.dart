/// SMAScreen - Special Mindfulness Activities management
/// 
/// List and manage SMAs with offline notifications. Provides CRUD operations
/// for creating custom mindfulness reminders with flexible scheduling.

library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sma.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/notification_persistence.dart';
import '../ui/layout.dart';
import '../ui/tokens.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_button.dart';

class SMAScreen extends StatefulWidget {
  const SMAScreen({super.key});

  @override
  State<SMAScreen> createState() => _SMAScreenState();
}

class _SMAScreenState extends State<SMAScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  List<SMA> _smas = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    await _notificationService.initialize();
    
    // Check if notifications need restoration (boot recovery)
    final persistenceService = NotificationPersistence();
    final restored = await persistenceService.restoreNotificationsIfNeeded();
    if (restored) {
      debugPrint('[SMA Screen] Notifications restored after app restart');
    }
    
    await _loadSMAs();
  }

  Future<void> _loadSMAs() async {
    final smasResult = await _databaseService.getAllSMAs();
    if (mounted) {
      setState(() {
        _smas = smasResult.getOrElse([]);
        _loading = false;
      });
      
      if (smasResult.isFailure) {
        debugPrint('Failed to load SMAs: ${smasResult.error}');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Special Mindfulness Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: AppScaffoldBody(
        padding: const EdgeInsets.symmetric(vertical: Spacing.s16),
        child: Column(
          children: [
            // Notification status banner
            if (!_notificationService.areNotificationsEnabled)
              Container(
                margin: const EdgeInsets.only(bottom: Spacing.s16),
                padding: const EdgeInsets.all(Spacing.s12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(26, 255, 152, 0),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_off, color: Colors.orange, size: 20),
                    const SizedBox(width: Spacing.s8),
                    Expanded(
                      child: Text(
                        'Notifications disabled. SMAs will work without reminders.',
                        style: TextStyle(color: Colors.orange[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Main content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSMAGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSMAGrid() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadSMAs();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (_smas.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Create up to 5 mindfulness activities to practice throughout your day',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ...List.generate(5, (index) {
            if (index < _smas.length) {
              return _buildFilledCard(_smas[index]);
            } else {
              return _buildEmptyCard(index);
            }
          }),
        ],
      ),
    );
  }

  Widget _buildFilledCard(SMA sma) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSMADialog(sma: sma),
        onLongPress: () => _deleteSMA(sma),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      sma.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    value: sma.notificationsEnabled,
                    onChanged: (enabled) => _toggleSMANotifications(sma, enabled),
                    activeTrackColor: const Color(0xFF20b2aa),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sma.frequencyDescription,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              if (sma.reminderWindows.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Times: ${sma.reminderWindowsDescription}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to edit • Long press to delete',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSMADialog(),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
              style: BorderStyle.solid,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 32,
                color: Colors.grey[500],
              ),
              const SizedBox(height: 8),
              Text(
                'Add Activity',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to create',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSMADialog({SMA? sma}) {
    // Check if we're trying to create a new SMA and already have 5
    if (sma == null && _smas.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 5 activities allowed. Delete one to add another.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => SMADialog(
        sma: sma,
        onSave: (newSMA) async {
          try {
            if (sma == null) {
              debugPrint('[SMA] Creating: ${newSMA.name}, frequency=${newSMA.frequency}, windows=${newSMA.reminderWindows.join(",")}');
              await _databaseService.saveSMA(newSMA);
            } else {
              debugPrint('[SMA] Updating: ${newSMA.name}, notifications=${newSMA.notificationsEnabled}');
              await _databaseService.updateSMA(newSMA);
            }
            
            await _loadSMAs();
            await _rescheduleNotifications();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(sma == null ? 'Activity created' : 'Activity updated'),
                  backgroundColor: const Color(0xFF20b2aa),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _toggleSMANotifications(SMA sma, bool enabled) async {
    try {
      debugPrint('[SMA] Notifications toggled: ${sma.name} = $enabled');
      final updatedSMA = sma.copyWith(notificationsEnabled: enabled);
      await _databaseService.updateSMA(updatedSMA);
      await _loadSMAs();
      await _rescheduleNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Notifications enabled' : 'Notifications disabled'),
            backgroundColor: const Color(0xFF20b2aa),
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to toggle notifications: $e');
    }
  }

  Future<void> _deleteSMA(SMA sma) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete Activity',
      content: Text('Delete "${sma.name}"?\n\nThis will also cancel all its notifications.'),
      actions: [
        AppButton.quiet('Cancel', onPressed: () => Navigator.of(context).pop(false)),
        const SizedBox(width: Spacing.s8),
        AppButton.danger('Delete', onPressed: () => Navigator.of(context).pop(true)),
      ],
    );

    if (confirmed == true) {
      try {
        debugPrint('[SMA] Deleting: ${sma.name} (${sma.id})');
        await _databaseService.deleteSMA(sma.id);
        await _notificationService.cancelSMANotifications(sma.id);
        await _loadSMAs();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity deleted'),
              backgroundColor: Color(0xFF20b2aa),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting activity: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rescheduleNotifications() async {
    final enabledSMAs = _smas.where((sma) => sma.notificationsEnabled).toList();
    debugPrint('[SMA] Rescheduling notifications for ${enabledSMAs.length} enabled SMAs');
    await _notificationService.scheduleAllSMAs(enabledSMAs);
    
    // Show pending count to user as feedback
    final count = await _notificationService.getPendingNotificationCount();
    debugPrint('[SMA] Schedule result: $count notifications scheduled');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scheduled $count reminder notifications'),
          backgroundColor: const Color(0xFF20b2aa),
        ),
      );
    }
  }


  void _showInfoDialog() {
    AppDialog.show(
      context: context,
      title: 'Special Mindfulness Activities',
      content: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SMAs are custom mindfulness reminders for daily activities like:',
            style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFFe5e5e5)),
          ),
          SizedBox(height: 8),
          Text('• "Notice 3 things" when opening doors', style: TextStyle(color: Color(0xFFe5e5e5))),
          Text('• "Take a breath" at traffic lights', style: TextStyle(color: Color(0xFFe5e5e5))),
          Text('• "Feel your feet" when walking', style: TextStyle(color: Color(0xFFe5e5e5))),
          SizedBox(height: 12),
          Text('Features:', style: TextStyle(fontWeight: FontWeight.w500, color: Color(0xFFe5e5e5))),
          SizedBox(height: 4),
          Text('• Fully offline notifications', style: TextStyle(color: Color(0xFFe5e5e5))),
          Text('• Flexible scheduling (daily, weekly, monthly)', style: TextStyle(color: Color(0xFFe5e5e5))),
          Text('• Multiple time windows per day', style: TextStyle(color: Color(0xFFe5e5e5))),
          Text('• Smart randomized timing', style: TextStyle(color: Color(0xFFe5e5e5))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
      ],
    );
  }
}

class SMADialog extends StatefulWidget {
  final SMA? sma;
  final Function(SMA) onSave;

  const SMADialog({
    super.key,
    this.sma,
    required this.onSave,
  });

  @override
  State<SMADialog> createState() => _SMADialogState();
}

class _SMADialogState extends State<SMADialog> {
  late TextEditingController _nameController;
  String _frequency = 'daily';
  Set<String> _reminderWindows = {'morning', 'midday', 'afternoon', 'evening'};
  bool _notificationsEnabled = true;
  int _dayOfWeek = 1;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    
    // Add listener to trigger save button state updates when name changes
    _nameController.addListener(() {
      setState(() {});
    });
    
    if (widget.sma != null) {
      final sma = widget.sma!;
      _nameController.text = sma.name;
      _frequency = sma.frequency;
      _reminderWindows = Set.from(sma.reminderWindows);
      _notificationsEnabled = sma.notificationsEnabled;
      _dayOfWeek = sma.dayOfWeek;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.sma == null ? 'Create Activity' : 'Edit Activity',
      showClose: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Activity Name',
                hintText: 'e.g., "Opening and closing doors"',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 16),
            
            Text('Frequency', style: Theme.of(context).textTheme.titleSmall),
            ...['daily', 'weekly', 'monthly', 'multiple'].map((freq) {
              return ListTile(
                title: Text(_getFrequencyLabel(freq)),
                leading: Radio<String>(
                  value: freq,
                  groupValue: _frequency,
                  onChanged: (value) => setState(() => _frequency = value!),
                ),
                onTap: () => setState(() => _frequency = freq),
                contentPadding: EdgeInsets.zero,
              );
            }),


            if (_frequency == 'weekly') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Day of week: '),
                  DropdownButton<int>(
                    value: _dayOfWeek,
                    items: [
                      const DropdownMenuItem(value: 1, child: Text('Monday')),
                      const DropdownMenuItem(value: 2, child: Text('Tuesday')),
                      const DropdownMenuItem(value: 3, child: Text('Wednesday')),
                      const DropdownMenuItem(value: 4, child: Text('Thursday')),
                      const DropdownMenuItem(value: 5, child: Text('Friday')),
                      const DropdownMenuItem(value: 6, child: Text('Saturday')),
                      const DropdownMenuItem(value: 0, child: Text('Sunday')),
                    ],
                    onChanged: (value) => setState(() => _dayOfWeek = value!),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Text('Reminder Times', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...['morning', 'midday', 'afternoon', 'evening'].map((window) {
              return CheckboxListTile(
                title: Text('${window[0].toUpperCase()}${window.substring(1)} (${_getWindowTime(window)})'),
                value: _reminderWindows.contains(window),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _reminderWindows.add(window);
                    } else {
                      _reminderWindows.remove(window);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),

            // Notifications are enabled by default - users can toggle in the list view
        ],
      ),
      actions: [
        AppButton.quiet('Cancel', onPressed: () => Navigator.of(context).pop()),
        AppButton.primary(widget.sma == null ? 'Create' : 'Save', onPressed: _canSave() ? _save : null),
      ],
    );
  }

  String _getFrequencyLabel(String freq) {
    switch (freq) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      case 'multiple': return 'Multiple times daily';
      default: return freq;
    }
  }

  String _getWindowTime(String window) {
    switch (window) {
      case 'morning': return '6-10am';
      case 'midday': return '10am-2pm';
      case 'afternoon': return '2-6pm';
      case 'evening': return '6-10pm';
      default: return '';
    }
  }

  bool _canSave() {
    return _nameController.text.trim().isNotEmpty && _reminderWindows.isNotEmpty;
  }

  void _save() {
    final sma = SMA(
      id: widget.sma?.id ?? 'sma_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      frequency: _frequency,
      timesPerDay: _reminderWindows.length, // Use actual count of selected windows
      reminderWindows: _reminderWindows.toList(),
      notificationsEnabled: _notificationsEnabled,
      dayOfWeek: _dayOfWeek,
      createdAt: widget.sma?.createdAt ?? DateTime.now(),
    );

    widget.onSave(sma);
    Navigator.of(context).pop();
  }
}
