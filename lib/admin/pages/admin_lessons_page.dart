import 'package:flutter/material.dart';
import '../../models/admin_models.dart';
import '../../models/app_models.dart';
import '../../services/admin_database_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/neo_brutal_widgets.dart';

class AdminLessonsPage extends StatefulWidget {
  const AdminLessonsPage({super.key});

  @override
  State<AdminLessonsPage> createState() => _AdminLessonsPageState();
}

class _AdminLessonsPageState extends State<AdminLessonsPage> with SingleTickerProviderStateMixin {
  final AdminDatabaseService _adminDbService = AdminDatabaseService();
  late TabController _tabController;
  String? _selectedCategoryId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChunkyTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLessonsTab(),
              _buildSignsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChunkyTabBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.inkBlack, width: 4)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(
          color: AppTheme.signalYellow,
          border: Border(bottom: BorderSide(color: AppTheme.inkBlack, width: 6)),
        ),
        labelColor: AppTheme.inkBlack,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        unselectedLabelColor: Colors.black38,
        tabs: const [Tab(text: 'LESSONS'), Tab(text: 'SIGN DATA')],
      ),
    );
  }

  Widget _buildLessonsTab() {
    return Row(
      children: [
        _buildSidebar(),
        const VerticalDivider(width: 4, thickness: 4, color: AppTheme.inkBlack),
        Expanded(
          child: Column(
            children: [
              _buildToolbar(),
              Expanded(child: _buildLessonsGrid()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppTheme.paperCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('DATABASE: PKGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          _sidebarItem(null, 'ALL REPOS', Icons.storage_rounded),
          Expanded(
            child: StreamBuilder<List<CategoryModel>>(
              stream: _adminDbService.categoriesStream(),
              builder: (context, snapshot) {
                final cats = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: cats.length,
                  itemBuilder: (context, i) => _sidebarItem(cats[i].id, cats[i].name, Icons.folder_rounded),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: NeoButton(
              label: 'NEW REPO', 
              color: AppTheme.mintGreen, 
              onPressed: () {}
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(String? id, String label, IconData icon) {
    bool selected = _selectedCategoryId == id;
    return ListTile(
      onTap: () => setState(() => _selectedCategoryId = id),
      leading: Icon(icon, color: AppTheme.inkBlack),
      title: Text(
        label.toUpperCase(), 
        style: TextStyle(fontWeight: selected ? FontWeight.w900 : FontWeight.w700, fontSize: 13)
      ),
      tileColor: selected ? AppTheme.signalYellow : null,
      shape: Border(bottom: BorderSide(color: AppTheme.inkBlack.withValues(alpha: 0.1))),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.inkBlack, width: 3))
      ),
      child: Row(
        children: [
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 16),
          NeoButton(
            label: 'INITIALIZE PKG', 
            color: AppTheme.electricBlue, 
            icon: Icons.add_circle_rounded, 
            onPressed: () {}
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return NeoPanel(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'FILTER ENTITIES...', 
          border: InputBorder.none, 
          icon: Icon(Icons.search_rounded)
        ),
      ),
    );
  }

  Widget _buildLessonsGrid() {
    return FutureBuilder<List<AdminLessonModel>>(
      future: _adminDbService.getAllLessons(),
      builder: (context, snapshot) {
        final lessons = snapshot.data ?? [];
        final filtered = lessons.where((l) {
          final matchesSearch = l.title.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategoryId == null || l.categoryId == _selectedCategoryId;
          return matchesSearch && matchesCategory;
        }).toList();

        return GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, i) => _lessonCard(filtered[i]),
        );
      },
    );
  }

  Widget _lessonCard(AdminLessonModel lesson) {
    return NeoPanel(
      color: lesson.isPublished ? AppTheme.softPeach : AppTheme.paperCream,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              NeoSticker(
                label: lesson.isPublished ? 'PUBLIC' : 'DRAFT', 
                color: lesson.isPublished ? AppTheme.mintGreen : AppTheme.signalYellow, 
                icon: Icons.sensors_rounded
              ),
              const Icon(Icons.more_horiz_rounded),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lesson.title.toUpperCase(), 
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -1)
          ),
          const Spacer(),
          Text(
            '${lesson.totalSigns} SIGN-CHIPS', 
            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black54, fontSize: 12)
          ),
          const SizedBox(height: 8),
          NeoButton(
            label: 'EDIT PKG', 
            color: Colors.white, 
            padding: const EdgeInsets.all(8), 
            onPressed: () {}
          ),
        ],
      ),
    );
  }

  Widget _buildSignsTab() {
    return const Center(
      child: Text('SIGN DATA REPOSITORY', style: TextStyle(fontWeight: FontWeight.w900))
    );
  }
}
