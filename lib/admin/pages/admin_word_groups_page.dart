import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../services/admin_database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

class AdminWordGroupsPage extends StatefulWidget {
  const AdminWordGroupsPage({super.key});

  @override
  State<AdminWordGroupsPage> createState() => _AdminWordGroupsPageState();
}

class _AdminWordGroupsPageState extends State<AdminWordGroupsPage> {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  String? _selectedGroupId;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Word Groups Sidebar
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: AppTheme.paperCream,
            border: Border(right: BorderSide(color: AppTheme.inkBlack, width: 4)),
          ),
          child: _buildGroupsSidebar(),
        ),
        // Words Content
        Expanded(child: _buildWordsContent()),
      ],
    );
  }

  Widget _buildGroupsSidebar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.inkBlack, width: 4)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Text(
                'WORD GROUPS', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)
              ),
              const Spacer(),
              IconButton(
                onPressed: () {}, 
                icon: const Icon(Icons.add_circle_rounded, color: AppTheme.mintGreen, size: 32)
              ),
            ],
          ),
        ),
        _buildSearchField(),
        Expanded(
          child: StreamBuilder<List<WordGroupModel>>(
            stream: _adminDbService.wordGroupsStream(),
            builder: (context, snapshot) {
              final groups = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (context, i) => _groupTile(groups[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: NeoPanel(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: const InputDecoration(
            hintText: 'FILTER GROUPS...', 
            border: InputBorder.none, 
            icon: Icon(Icons.search_rounded)
          ),
        ),
      ),
    );
  }

  Widget _groupTile(WordGroupModel group) {
    bool selected = _selectedGroupId == group.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedGroupId = group.id),
        child: NeoPanel(
          color: selected ? AppTheme.signalYellow : Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.text_fields_rounded, color: AppTheme.inkBlack),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name.toUpperCase(), 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)
                    ),
                    Text(
                      '${group.words.length} SIGN-GEMS', 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Colors.black54)
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordsContent() {
    if (_selectedGroupId == null) {
      return const NeoEmptyState(
        icon: Icons.touch_app_rounded, 
        title: 'NO GROUP SELECTED', 
        subtitle: 'Select a group from the sidebar to modify signs.'
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.inkBlack, width: 4)),
          ),
          child: Row(
            children: [
              const Text(
                'ACTIVE SIGNS', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1)
              ),
              const Spacer(),
              NeoButton(
                label: 'APPEND SIGN', 
                color: AppTheme.mintGreen, 
                icon: Icons.add_rounded, 
                onPressed: () {}
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<WordModel>>(
            stream: _adminDbService.wordsStream(_selectedGroupId!),
            builder: (context, snapshot) {
              final words = snapshot.data ?? [];
              return GridView.builder(
                padding: const EdgeInsets.all(32),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 1,
                ),
                itemCount: words.length,
                itemBuilder: (context, i) => _signCard(words[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _signCard(WordModel word) {
    return NeoPanel(
      color: AppTheme.warmWhite,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.electricBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.inkBlack, width: 2),
            ),
            child: const Icon(Icons.abc_rounded, size: 32, color: AppTheme.inkBlack),
          ),
          const SizedBox(height: 16),
          Text(
            word.text.toUpperCase(), 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -1)
          ),
          const SizedBox(height: 4),
          Text(
            '${word.characters.length} CHARS', 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.black54)
          ),
          const Spacer(),
          NeoButton(
            label: 'CONFIG', 
            color: Colors.white, 
            padding: const EdgeInsets.all(8), 
            onPressed: () {}
          ),
        ],
      ),
    );
  }
}
