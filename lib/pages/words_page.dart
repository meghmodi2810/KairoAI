import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/sign_image_service.dart';

/// Word Practice section — replaces Quiz tab.
/// Fetches word_groups from Firestore, lets learners unlock & practice words.
class WordsPage extends StatefulWidget {
  const WordsPage({super.key});

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _userGems = 0;

  @override
  void initState() {
    super.initState();
    _loadUserGems();
  }

  Future<void> _loadUserGems() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists && mounted) {
      setState(() => _userGems = (doc.data()?['gems'] ?? 0) as int);
    }
  }

  Future<void> _unlockGroup(String groupId, int gemCost) async {
    if (_userGems < gemCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough gems to unlock this group!'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Unlock Word Group', style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          'Spend $gemCost gems to unlock this word group?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unlock'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Deduct gems
    await _db.collection('users').doc(uid).update({
      'gems': FieldValue.increment(-gemCost),
    });

    // Record unlocked group
    await _db.collection('users').doc(uid).collection('unlocked_word_groups').doc(groupId).set({
      'unlockedAt': FieldValue.serverTimestamp(),
    });

    _loadUserGems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        automaticallyImplyLeading: false,
        title: const Text('Word Practice', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.gemPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.diamond, color: AppTheme.gemPurple, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$_userGems',
                  style: const TextStyle(color: AppTheme.gemPurple, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildGroupsList(),
    );
  }

  Widget _buildGroupsList() {
    final uid = _auth.currentUser?.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('word_groups').orderBy('order').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.text_fields_rounded, color: AppTheme.textMuted, size: 56),
                SizedBox(height: 16),
                Text('No word groups yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
                SizedBox(height: 8),
                Text('Word groups will appear here once the admin adds them.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
              ],
            ),
          );
        }

        final groups = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            final data = group.data() as Map<String, dynamic>;
            final name = data['name'] ?? 'Untitled';
            final wordCount = data['wordCount'] ?? 0;
            final difficulty = data['difficulty'] ?? 'Beginner';
            final gemCost = data['gemCost'] ?? 0;
            final isLocked = gemCost > 0;

            return FutureBuilder<DocumentSnapshot>(
              future: uid != null
                  ? _db.collection('users').doc(uid).collection('unlocked_word_groups').doc(group.id).get()
                  : Future.value(null as DocumentSnapshot?),
              builder: (context, unlockSnap) {
                final isUnlocked = unlockSnap.data?.exists == true || !isLocked;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isUnlocked ? AppTheme.primaryIndigo.withOpacity(0.3) : AppTheme.dividerColor),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isUnlocked
                          ? () => _openWordGroup(group.id, name)
                          : () => _unlockGroup(group.id, gemCost),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? AppTheme.primaryIndigo.withOpacity(0.15)
                                    : AppTheme.cardLight,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isUnlocked ? Icons.text_fields : Icons.lock,
                                color: isUnlocked ? AppTheme.primaryIndigo : AppTheme.textMuted,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _badge(difficulty),
                                      const SizedBox(width: 10),
                                      Text(
                                        '$wordCount words',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!isUnlocked)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.gemPurple.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.diamond, color: AppTheme.gemPurple, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$gemCost',
                                      style: const TextStyle(
                                        color: AppTheme.gemPurple,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _badge(String text) {
    Color c;
    switch (text.toLowerCase()) {
      case 'beginner':
        c = AppTheme.accentGreen;
        break;
      case 'intermediate':
        c = AppTheme.accentAmber;
        break;
      case 'advanced':
        c = AppTheme.errorRed;
        break;
      default:
        c = AppTheme.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  void _openWordGroup(String groupId, String groupName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordGroupDetailPage(groupId: groupId, groupName: groupName),
      ),
    );
  }
}

/// Shows all words in a group and lets the learner practice
class WordGroupDetailPage extends StatelessWidget {
  final String groupId;
  final String groupName;

  const WordGroupDetailPage({super.key, required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        title: Text(groupName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('word_groups')
            .doc(groupId)
            .collection('words')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No words in this group yet.', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          final words = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: words.length,
            itemBuilder: (context, index) {
              final data = words[index].data() as Map<String, dynamic>;
              final text = data['text'] ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WordPracticePage(word: text),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryIndigo.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.sign_language, color: AppTheme.primaryIndigo, size: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${text.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').length} characters',
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.play_circle_outline, color: AppTheme.primaryIndigo, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Displays each character of a word as ISL signs sequentially
class WordPracticePage extends StatefulWidget {
  final String word;
  const WordPracticePage({super.key, required this.word});

  @override
  State<WordPracticePage> createState() => _WordPracticePageState();
}

class _WordPracticePageState extends State<WordPracticePage> {
  final SignImageService _signService = SignImageService();
  late List<String> _characters;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _characters = _signService.splitWordToCharacters(widget.word);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_characters.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: Text('Practice: ${widget.word}'),
        ),
        body: const Center(
          child: Text('No sign characters found for this word.', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildCharView()),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _characters.length,
                    minHeight: 6,
                    backgroundColor: AppTheme.cardLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentAmber),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentIndex + 1}/${_characters.length}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Word with current char highlighted
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _characters.asMap().entries.map((entry) {
              final isCurrent = entry.key == _currentIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCurrent ? AppTheme.primaryIndigo : AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(8),
                  border: isCurrent ? null : Border.all(color: AppTheme.dividerColor),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: isCurrent ? Colors.white : AppTheme.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCharView() {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _characters.length,
      itemBuilder: (context, index) {
        final char = _characters[index];

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign for "$char"',
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: FutureBuilder<dynamic>(
                      future: _signService.getRandomImage(char),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryIndigo));
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => _placeholder(char),
                          );
                        }
                        return _placeholder(char);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder(String char) {
    return Container(
      color: AppTheme.cardLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sign_language, color: AppTheme.textMuted, size: 56),
            const SizedBox(height: 8),
            Text(char, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 36, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLast = _currentIndex == _characters.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Row(
        children: [
          if (_currentIndex > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _currentIndex--);
                  _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.dividerColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Previous'),
              ),
            ),
          if (_currentIndex > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Great job! You practiced "${widget.word}" 🎉'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                } else {
                  setState(() => _currentIndex++);
                  _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? AppTheme.accentGreen : AppTheme.primaryIndigo,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(isLast ? 'Done' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }
}
