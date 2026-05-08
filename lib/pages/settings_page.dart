import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _soundEnabled = true;
  NotificationVerbosity _verbosity = NotificationVerbosity.all;
  int? _reminderHour;
  int? _reminderMinute;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = AudioService().soundEnabled;
      _verbosity = NotificationService().verbosity;
      _reminderHour = prefs.getInt('custom_reminder_hour');
      _reminderMinute = prefs.getInt('custom_reminder_minute');
    });
  }

  Future<void> _toggleSound(bool value) async {
    await AudioService().setSoundEnabled(value);
    setState(() {
      _soundEnabled = value;
    });
  }

  Future<void> _updateVerbosity(NotificationVerbosity? value) async {
    if (value == null) return;
    await NotificationService().setVerbosity(value);
    setState(() {
      _verbosity = value;
    });
  }

  Future<void> _pickReminderTime() async {
    final initialTime = _reminderHour != null && _reminderMinute != null
        ? TimeOfDay(hour: _reminderHour!, minute: _reminderMinute!)
        : const TimeOfDay(hour: 10, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.cobaltBlue,
              onPrimary: Colors.white,
              surface: AppTheme.paperCream,
              onSurface: AppTheme.inkBlack,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await NotificationService().setCustomReminderTime(picked.hour, picked.minute);
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder set for ${picked.format(context)}'),
            backgroundColor: AppTheme.mintGreen,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String reminderText = 'Not set';
    if (_reminderHour != null && _reminderMinute != null) {
      final time = TimeOfDay(hour: _reminderHour!, minute: _reminderMinute!);
      reminderText = time.format(context);
    }

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.warmWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.inkBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.inkBlack,
                            blurRadius: 0,
                            offset: Offset(3, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.inkBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeoPanel(
                      color: AppTheme.signalYellow,
                      radius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shadow: false,
                      child: const Text(
                        'SETTINGS',
                        style: TextStyle(
                          color: AppTheme.inkBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  NeoPanel(
                    color: AppTheme.warmWhite,
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PREFERENCES',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sound Effects',
                              style: TextStyle(
                                color: AppTheme.inkBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Switch(
                              value: _soundEnabled,
                              onChanged: _toggleSound,
                              activeColor: AppTheme.mintGreen,
                              activeTrackColor: AppTheme.inkBlack,
                              inactiveThumbColor: AppTheme.paperCream,
                              inactiveTrackColor: AppTheme.inkBlack.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.inkBlack, thickness: 2, height: 24),
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.paperCream,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.inkBlack, width: 2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<NotificationVerbosity>(
                              value: _verbosity,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.inkBlack),
                              items: const [
                                DropdownMenuItem(
                                  value: NotificationVerbosity.off,
                                  child: Text('Turn off all', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                DropdownMenuItem(
                                  value: NotificationVerbosity.minimal,
                                  child: Text('Minimal notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                DropdownMenuItem(
                                  value: NotificationVerbosity.all,
                                  child: Text('All notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                              onChanged: _updateVerbosity,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daily Reminder',
                              style: TextStyle(
                                color: AppTheme.inkBlack,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _pickReminderTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cobaltBlue,
                                foregroundColor: AppTheme.warmWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: AppTheme.inkBlack, width: 2),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Text(
                                reminderText,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: AppTheme.inkBlack, thickness: 2, height: 24),
                        NeoSecondaryButton(
                          label: 'Send Test Notification',
                          onPressed: () async {
                            await NotificationService().sendTestNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test notification will appear in ~3 seconds.'),
                                  backgroundColor: AppTheme.mintGreen,
                                ),
                              );
                            }
                          },
                          icon: Icons.notifications_active_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  NeoPanel(
                    color: AppTheme.warmWhite,
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SUPPORT',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        NeoPrimaryButton(
                          label: 'Need Help',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Help and support will be available soon.')),
                            );
                          },
                          icon: Icons.help_outline,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  NeoPanel(
                    color: AppTheme.warmWhite,
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACCOUNT',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final email = FirebaseAuth.instance.currentUser?.email;
                              if (email != null && email.isNotEmpty) {
                                try {
                                  await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password reset email sent.'),
                                      backgroundColor: AppTheme.mintGreen,
                                    ),
                                  );
                                } catch (_) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to send reset email.'),
                                      backgroundColor: AppTheme.punchRed,
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.lock_reset_rounded),
                            label: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.inkBlack, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.paperCream,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: AppTheme.inkBlack, width: 3),
                                  ),
                                  title: const Text(
                                    'Log Out',
                                    style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.inkBlack),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to log out?',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.inkBlack),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel', style: TextStyle(color: AppTheme.inkBlack, fontWeight: FontWeight.bold)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.punchRed,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseAuth.instance.signOut();
                                if (!context.mounted) return;
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                  (_) => false,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.punchRed,
                              foregroundColor: AppTheme.warmWhite,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppTheme.inkBlack, width: 2),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Log out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
