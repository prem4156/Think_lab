import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/daily_workout.dart';
import '../models/game_result.dart';
import '../models/user_profile.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'bpi_analytics_screen.dart';
import 'game_modal_tutorial.dart';
import 'level_journey_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile? profile;
  DailyWorkout? workout;
  bool isLoading = true;
  int currentTab = 0;
  CognitiveDomain? selectedDomainFilter;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    final prof = await StorageService.instance.loadProfile();
    final work = await StorageService.instance.loadDailyWorkout();
    if (mounted) {
      setState(() {
        profile = prof;
        workout = work;
        isLoading = false;
      });
    }
  }

  void _openGameTutorial(String gameId) {
    if (profile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameModalTutorial(
        gameId: gameId,
        profile: profile!,
        onWorkoutGameFinished: _loadDashboardData,
      ),
    );
  }

  void _startNextDailyWorkoutGame() {
    if (workout == null) return;
    for (String gameId in workout!.gameIds) {
      if (!workout!.completedGameIds.contains(gameId)) {
        _openGameTutorial(gameId);
        return;
      }
    }
  }

  void _handleLogout() async {
    SoundService.instance.playTap();
    await StorageService.instance.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || profile == null || workout == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: IndexedStack(
        index: currentTab,
        children: [
          LevelJourneyScreen(
            profile: profile!,
            onProgressUpdated: _loadDashboardData,
          ),
          _buildHomeTab(),
          const BpiAnalyticsScreen(),
          ProfileScreen(onProfileUpdated: _loadDashboardData),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  Widget _buildFloatingBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.surfaceCardBorder),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNeon.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.map_rounded, 'Journey'),
          _navItem(1, Icons.fitness_center_rounded, 'Mind Gym'),
          _navItem(2, Icons.insights_rounded, 'Analytics'),
          _navItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    bool isSelected = currentTab == index;
    Color activeColor = AppTheme.primaryNeon;

    return InkWell(
      onTap: () {
        SoundService.instance.playTap();
        setState(() {
          currentTab = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : AppTheme.textMuted,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Header with Avatar & Badges
            _buildTopHeader()
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.1, end: 0),
            const SizedBox(height: 20),

            // Hero Daily Workout Card
            _buildDailyWorkoutCard()
                .animate()
                .fadeIn(duration: 500.ms, delay: 100.ms)
                .slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            // Live Search Input Box
            _buildSearchBar()
                .animate()
                .fadeIn(duration: 400.ms, delay: 150.ms),

            const SizedBox(height: 16),

            // Cognitive Domain Filter Bar
            _buildDomainFilterBar()
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),

            const SizedBox(height: 20),

            // Minigames Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDomainFilter == null
                      ? 'MINIGAMES (${_getFilteredGames().length})'
                      : '${selectedDomainFilter!.displayName.toUpperCase()} GAMES',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                Text(
                  '${_getFilteredGames().length} available',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 250.ms),

            const SizedBox(height: 14),

            // Minigames Grid
            _buildMinigamesGrid()
                .animate()
                .fadeIn(duration: 500.ms, delay: 300.ms),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  currentTab = 3; // Jump to profile tab
                });
              },
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.surfaceCard,
                  child: Text(
                    '🧠',
                    style: TextStyle(fontSize: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Text(
                      'THINK CITY',
                      style: TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Welcome, ${profile?.name ?? 'Trainer'}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            // Logout Icon Button
            InkWell(
              onTap: _handleLogout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceCardBorder),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.textMuted,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Streak Flame Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.amberProblemSolving.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.amberProblemSolving.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.amberProblemSolving.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 15)),
                  const SizedBox(width: 4),
                  Text(
                    '${profile!.currentStreak}',
                    style: const TextStyle(
                      color: AppTheme.amberProblemSolving,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // BPI Score Chip Button
            InkWell(
              onTap: () {
                SoundService.instance.playTap();
                setState(() {
                  currentTab = 2; // Jump to analytics
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.purpleMemory.withValues(alpha: 0.15),
                      AppTheme.primaryNeon.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.purpleMemory.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology,
                        color: AppTheme.purpleMemory, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      '${profile!.overallBpi}',
                      style: const TextStyle(
                        color: AppTheme.purpleMemory,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyWorkoutCard() {
    bool completed = workout!.isCompleted;
    double progress = workout!.progressFraction;
    int doneCount = workout!.completedGameIds.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: completed
              ? AppTheme.emeraldAttention.withValues(alpha: 0.6)
              : AppTheme.surfaceCardBorder,
          width: completed ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (completed
                    ? AppTheme.emeraldAttention
                    : AppTheme.primaryNeon)
                .withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          children: [
            // Top Colored Indicator Bar
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: completed
                    ? AppTheme.attentionGradient
                    : AppTheme.primaryGradient,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (completed
                                  ? AppTheme.emeraldAttention
                                  : AppTheme.primaryNeon)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              completed
                                  ? Icons.check_circle
                                  : Icons.fitness_center,
                              size: 14,
                              color: completed
                                  ? AppTheme.emeraldAttention
                                  : AppTheme.primaryNeon,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              completed
                                  ? 'WORKOUT COMPLETED! 🎉'
                                  : 'TODAY\'S MIND GYM',
                              style: TextStyle(
                                color: completed
                                    ? AppTheme.emeraldAttention
                                    : AppTheme.primaryNeon,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$doneCount / 3 COMPLETED',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Brain Workout',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Targeted 3-game session designed to optimize your cognitive performance.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppTheme.bgDark,
                      color: completed
                          ? AppTheme.emeraldAttention
                          : AppTheme.primaryNeon,
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3 Minigame Steps Quick Preview Cards
                  Row(
                    children: workout!.gameIds.map((gameId) {
                      bool isDone = workout!.completedGameIds.contains(gameId);
                      final meta = GameModalTutorial.gameMeta[gameId];
                      Color domainColor =
                          meta != null ? meta['color'] : AppTheme.primaryNeon;
                      IconData icon = meta != null ? meta['icon'] : Icons.extension;

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isDone
                                ? domainColor.withValues(alpha: 0.15)
                                : AppTheme.bgDark,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDone
                                  ? domainColor.withValues(alpha: 0.4)
                                  : AppTheme.surfaceCardBorder,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                isDone ? Icons.check_circle : icon,
                                size: 20,
                                color: isDone
                                    ? AppTheme.emeraldAttention
                                    : domainColor,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meta?['title']?.toString().split(' ').first ??
                                    'Game',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDone
                                      ? AppTheme.textPrimary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // CTA Action Button with Gradient
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: completed ? null : AppTheme.primaryGradient,
                        color: completed ? AppTheme.bgDark : null,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: completed
                            ? []
                            : [
                                BoxShadow(
                                  color: AppTheme.primaryNeon
                                      .withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed:
                            completed ? null : _startNextDailyWorkoutGame,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              completed
                                  ? Icons.stars
                                  : Icons.play_arrow_rounded,
                              color: completed
                                  ? AppTheme.emeraldAttention
                                  : Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              completed
                                  ? 'ALL DAILY GAMES FINISHED!'
                                  : 'START DAILY WORKOUT',
                              style: TextStyle(
                                color: completed
                                    ? AppTheme.emeraldAttention
                                    : Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceCardBorder),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (val) {
          setState(() {
            searchQuery = val.trim().toLowerCase();
          });
        },
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Search games by name or skill...',
          hintStyle: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppTheme.primaryNeon, size: 20),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      color: AppTheme.textMuted, size: 18),
                  onPressed: () {
                    searchController.clear();
                    setState(() {
                      searchQuery = '';
                    });
                  },
                )
              : null,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDomainFilterBar() {
    final List<CognitiveDomain?> domains = [
      null, // All
      ...CognitiveDomain.values,
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: domains.length,
        itemBuilder: (context, index) {
          final domain = domains[index];
          bool isSelected = selectedDomainFilter == domain;
          Color color = domain != null
              ? _getDomainColor(domain)
              : AppTheme.primaryNeon;

          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                SoundService.instance.playTap();
                setState(() {
                  selectedDomainFilter = domain;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : AppTheme.surfaceCardBorder,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    domain == null ? '⚡ All Domains' : domain.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredGames() {
    final List<Map<String, dynamic>> allGames = [
      {
        'id': 'spatial_memory',
        'title': 'Spatial Memory Matrix',
        'domain': CognitiveDomain.memory,
        'color': AppTheme.purpleMemory,
        'icon': Icons.grid_on,
        'desc': 'Visual pattern recall',
      },
      {
        'id': 'sequence_recall',
        'title': 'Sequence Recall',
        'domain': CognitiveDomain.memory,
        'color': AppTheme.purpleMemory,
        'icon': Icons.audiotrack,
        'desc': 'Audio-visual order',
      },
      {
        'id': 'stroop_match',
        'title': 'Stroop Color Match',
        'domain': CognitiveDomain.speed,
        'color': AppTheme.cyanSpeed,
        'icon': Icons.bolt,
        'desc': 'Processing speed',
      },
      {
        'id': 'rapid_math',
        'title': 'Rapid Math Inequalities',
        'domain': CognitiveDomain.problemSolving,
        'color': AppTheme.amberProblemSolving,
        'icon': Icons.calculate,
        'desc': 'Numerical logic',
      },
      {
        'id': 'flock_focus',
        'title': 'Flock Focus',
        'domain': CognitiveDomain.attention,
        'color': AppTheme.emeraldAttention,
        'icon': Icons.navigation,
        'desc': 'Selective attention',
      },
      {
        'id': 'eagle_eye',
        'title': 'Eagle Eye Dual Focus',
        'domain': CognitiveDomain.attention,
        'color': AppTheme.emeraldAttention,
        'icon': Icons.remove_red_eye,
        'desc': 'Peripheral scanner',
      },
      {
        'id': 'rule_switcher',
        'title': 'Rule Switcher Agility',
        'domain': CognitiveDomain.flexibility,
        'color': AppTheme.coralFlexibility,
        'icon': Icons.swap_calls,
        'desc': 'Task switching speed',
      },
      {
        'id': 'anagram_surge',
        'title': 'Anagram Surge',
        'domain': CognitiveDomain.language,
        'color': AppTheme.pinkLanguage,
        'icon': Icons.font_download,
        'desc': 'Word anagram fluency',
      },
    ];

    List<Map<String, dynamic>> list = allGames;

    if (selectedDomainFilter != null) {
      list = list.where((g) => g['domain'] == selectedDomainFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      list = list.where((g) {
        String t = (g['title'] as String).toLowerCase();
        String d = (g['desc'] as String).toLowerCase();
        return t.contains(searchQuery) || d.contains(searchQuery);
      }).toList();
    }

    return list;
  }

  Widget _buildMinigamesGrid() {
    final filteredGames = _getFilteredGames();

    if (filteredGames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceCardBorder),
        ),
        child: Column(
          children: const [
            Icon(Icons.search_off_rounded, size: 40, color: AppTheme.textMuted),
            SizedBox(height: 12),
            Text(
              'No minigames match your search.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.90,
      ),
      itemCount: filteredGames.length,
      itemBuilder: (context, index) {
        final g = filteredGames[index];
        String gameId = g['id'];
        String title = g['title'];
        CognitiveDomain domain = g['domain'];
        Color color = g['color'];
        IconData icon = g['icon'];
        String desc = g['desc'] ?? '';

        int highScore = profile!.highScores[gameId] ?? 0;

        return GestureDetector(
          onTap: () {
            SoundService.instance.playTap();
            _openGameTutorial(gameId);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.surfaceCardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.06),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Top Color Accent Bar
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 4,
                    child: Container(color: color),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(icon, color: color, size: 22),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                domain.displayName.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              desc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.emoji_events,
                                    size: 14,
                                    color: AppTheme.amberProblemSolving),
                                const SizedBox(width: 4),
                                Text(
                                  '$highScore',
                                  style: const TextStyle(
                                    color: AppTheme.amberProblemSolving,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getDomainColor(CognitiveDomain domain) {
    switch (domain) {
      case CognitiveDomain.speed:
        return AppTheme.cyanSpeed;
      case CognitiveDomain.memory:
        return AppTheme.purpleMemory;
      case CognitiveDomain.attention:
        return AppTheme.emeraldAttention;
      case CognitiveDomain.flexibility:
        return AppTheme.coralFlexibility;
      case CognitiveDomain.problemSolving:
        return AppTheme.amberProblemSolving;
      case CognitiveDomain.language:
        return AppTheme.pinkLanguage;
    }
  }
}
