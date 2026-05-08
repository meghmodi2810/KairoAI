import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/lesson_character_models.dart';
import '../services/database_service.dart';
import '../services/issue_report_service.dart';
import '../theme/app_theme.dart';
import '../theme/neo_brutal_widgets.dart';
import 'settings_page.dart';

class ProfileTourTargets {
  static final completedSigns = GlobalKey(debugLabel: 'tour_completed_signs');
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final user = FirebaseAuth.instance.currentUser;
    if (uid == null || uid.isEmpty) {
      return const Scaffold(
        backgroundColor: AppTheme.paperCream,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.cobaltBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.paperCream,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;

          final name = (data?['displayName'] ?? user?.displayName ?? 'Learner')
              .toString();
          final email = user?.email ?? '';
          final xp = (data?['xp'] as num?)?.toInt() ?? 0;
          final storedLevel = data?['currentLevel'];
          final level = (storedLevel is int && storedLevel > 0)
              ? storedLevel
              : DatabaseService.computeLevel(xp);
          final streak = (data?['streakDays'] as num?)?.toInt() ?? 0;
          final gems = (data?['gems'] as num?)?.toInt() ?? 0;
          final completedSignCharacters = normalizeSignCharacters(
            (data?['completedSignCharacters'] as List<dynamic>? ?? const [])
                .map((value) => value.toString()),
          );
          final lessonsCompleted =
              (data?['totalLessonsCompleted'] as num?)?.toInt() ?? 0;
          final uniqueSigns = completedSignCharacters.length;
          final rawTotalSigns = data?['totalSignsLearned'];
          final totalSigns = rawTotalSigns is num
              ? rawTotalSigns.toInt()
              : (rawTotalSigns is String
                        ? int.tryParse(rawTotalSigns)
                        : null) ??
                    0;
          final signsLearned = totalSigns >= uniqueSigns
              ? totalSigns
              : uniqueSigns;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: NeoPanel(
                      color: AppTheme.electricBlue,
                      radius: 18,
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppTheme.signalYellow,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.inkBlack,
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _initials(name),
                                style: const TextStyle(
                                  color: AppTheme.inkBlack,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              color: AppTheme.inkBlack,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          NeoSticker(
                            label: 'LEVEL $level',
                            icon: Icons.military_tech,
                            color: AppTheme.signalYellow,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'XP',
                              value: '$xp',
                              color: AppTheme.signalYellow,
                              icon: Icons.bolt,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              label: 'STREAK',
                              value: '$streak',
                              color: AppTheme.punchRed,
                              icon: Icons.local_fire_department,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'GEMS',
                              value: '$gems',
                              color: AppTheme.gemPurple,
                              icon: Icons.diamond,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              label: 'LESSONS',
                              value: '$lessonsCompleted',
                              color: AppTheme.mintGreen,
                              icon: Icons.school,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: NeoPanel(
                    color: AppTheme.warmWhite,
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LEARNER PASSPORT',
                          style: TextStyle(
                            color: AppTheme.inkBlack,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _infoRow('Current tier', 'Level $level'),
                        const SizedBox(height: 8),
                        _infoRow('Support', 'Help and FAQ available'),
                        const SizedBox(height: 8),
                        _infoRow('Language', 'English'),
                        const SizedBox(height: 8),
                        _infoRow('Signs learned', '$signsLearned'),
                        const SizedBox(height: 8),
                        _infoRow(
                          'Completed signs',
                          '${completedSignCharacters.length}',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          key: ProfileTourTargets.completedSigns,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showCompletedSignsDialog(
                              context,
                              completedSignCharacters,
                            ),
                            icon: const Icon(Icons.front_hand_rounded),
                            label: const Text('Completed Signs'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: NeoPanel(
                    color: AppTheme.warmWhite,
                    radius: 18,
                    child: NeoPrimaryButton(
                      label: 'Settings',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                      icon: Icons.settings_rounded,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.inkBlack,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeoPanel(
      color: AppTheme.warmWhite,
      radius: 16,
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.inkBlack,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showCompletedSignsDialog(
  BuildContext context,
  List<String> completedSignCharacters,
) async {
  final alphabet =
      completedSignCharacters.where(isAlphabetSignCharacter).toList()..sort();
  final numbers = completedSignCharacters.where(isNumberSignCharacter).toList()
    ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Completed Signs'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (completedSignCharacters.isEmpty)
                const Text(
                  'Complete a lesson to start filling this collection.',
                ),
              if (alphabet.isNotEmpty) ...[
                const Text(
                  'Alphabet',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                _CompletedSignWrap(characters: alphabet),
              ],
              if (alphabet.isNotEmpty && numbers.isNotEmpty)
                const SizedBox(height: 16),
              if (numbers.isNotEmpty) ...[
                const Text(
                  'Numbers',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                _CompletedSignWrap(characters: numbers),
              ],
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

class _CompletedSignWrap extends StatelessWidget {
  final List<String> characters;

  const _CompletedSignWrap({required this.characters});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: characters
          .map(
            (character) => Container(
              width: 38,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.mintGreen,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppTheme.inkBlack, width: 2),
              ),
              child: Center(
                child: Text(
                  character,
                  style: const TextStyle(
                    color: AppTheme.inkBlack,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ignore: unused_element
Future<void> _showIssueReportDialog(
  BuildContext context, {
  required String reporterUid,
  required String reporterName,
  required String reporterEmail,
}) async {
  final hostContext = context;
  final titleCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final service = IssueReportService();
  String selectedType = 'other';
  String selectedPriority = 'medium';
  bool submitting = false;

  final submitted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (localContext, setLocalState) {
          return AlertDialog(
            title: const Text('Report an issue'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Short summary',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'What happened?',
                      hintText:
                          'Tell us what went wrong and what you expected.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'bug', child: Text('Bug')),
                      DropdownMenuItem(
                        value: 'content',
                        child: Text('Content issue'),
                      ),
                      DropdownMenuItem(
                        value: 'feature',
                        child: Text('Feature request'),
                      ),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => selectedType = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setLocalState(() => selectedPriority = value);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(
                        dialogContext,
                        rootNavigator: true,
                      ).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        final title = titleCtrl.text.trim();
                        final description = descriptionCtrl.text.trim();

                        if (title.isEmpty || description.isEmpty) {
                          if (!hostContext.mounted) return;
                          ScaffoldMessenger.of(hostContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please provide both title and details.',
                              ),
                            ),
                          );
                          return;
                        }

                        setLocalState(() => submitting = true);

                        try {
                          await service.submit(
                            IssueReportPayload(
                              title: title,
                              description: description,
                              type: selectedType,
                              priority: selectedPriority,
                              reporterUid: reporterUid,
                              reporterEmail: reporterEmail,
                              reporterDisplayName: reporterName,
                              sourceScreen: 'profile',
                              contextType: 'general_support',
                            ),
                          );

                          if (!dialogContext.mounted) return;
                          Navigator.of(
                            dialogContext,
                            rootNavigator: true,
                          ).pop(true);
                        } catch (_) {
                          if (!localContext.mounted) return;
                          setLocalState(() => submitting = false);
                          if (!hostContext.mounted) return;
                          ScaffoldMessenger.of(hostContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not submit issue right now. Please try again.',
                              ),
                            ),
                          );
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      );
    },
  );

  if (submitted == true && hostContext.mounted) {
    ScaffoldMessenger.of(hostContext).showSnackBar(
      const SnackBar(
        content: Text('Issue submitted. Our team will review it soon.'),
      ),
    );
  }

  Future<void>.delayed(const Duration(milliseconds: 250), () {
    titleCtrl.dispose();
    descriptionCtrl.dispose();
  });
}
