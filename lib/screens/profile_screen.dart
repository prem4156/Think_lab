import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_profile.dart';
import '../services/sound_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({Key? key, this.onProfileUpdated}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final prof = await StorageService.instance.loadProfile();
    if (mounted) {
      setState(() {
        profile = prof;
        isLoading = false;
      });
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

  String _getBpiTitle(int bpi) {
    if (bpi >= 900) return 'Grandmaster Mind 🧠⚡';
    if (bpi >= 750) return 'Cognitive Master 🏆';
    if (bpi >= 650) return 'Mind Athlete 🏃‍♂️';
    if (bpi >= 550) return 'Brain Trainer 🎯';
    return 'Novice Thinker 🌱';
  }

  void _showEditNameDialog() {
    TextEditingController editController =
        TextEditingController(text: profile?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Edit Display Name',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: TextField(
          controller: editController,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: const TextStyle(color: AppTheme.textMuted),
            filled: true,
            fillColor: AppTheme.bgDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              String newName = editController.text.trim();
              if (newName.isNotEmpty) {
                profile!.name = newName;
                await StorageService.instance.saveProfile(profile!);
                if (widget.onProfileUpdated != null) {
                  widget.onProfileUpdated!();
                }
                setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || profile == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryNeon),
        ),
      );
    }

    String titleRank = _getBpiTitle(profile!.overallBpi);

    final List<Map<String, dynamic>> achievements = [
      {
        'title': 'First Step',
        'desc': 'Complete your 1st workout',
        'icon': Icons.emoji_events,
        'unlocked': profile!.totalWorkoutsCompleted >= 1,
        'color': AppTheme.amberProblemSolving,
      },
      {
        'title': 'On Fire',
        'desc': 'Achieve a 3-day streak',
        'icon': Icons.local_fire_department,
        'unlocked': profile!.currentStreak >= 3,
        'color': AppTheme.coralFlexibility,
      },
      {
        'title': 'Speed Demon',
        'desc': 'Score 4000+ in Speed',
        'icon': Icons.bolt,
        'unlocked': (profile!.highScores['stroop_match'] ?? 0) >= 4000,
        'color': AppTheme.cyanSpeed,
      },
      {
        'title': 'Memory Master',
        'desc': 'Score 4000+ in Memory',
        'icon': Icons.psychology,
        'unlocked': (profile!.highScores['spatial_memory'] ?? 0) >= 4000,
        'color': AppTheme.purpleMemory,
      },
      {
        'title': 'Eagle Vision',
        'desc': 'Score 3500+ in Attention',
        'icon': Icons.remove_red_eye,
        'unlocked': (profile!.highScores['flock_focus'] ?? 0) >= 3500,
        'color': AppTheme.emeraldAttention,
      },
      {
        'title': 'Word Surge',
        'desc': 'Score 4000+ in Language',
        'icon': Icons.font_download,
        'unlocked': (profile!.highScores['anagram_surge'] ?? 0) >= 4000,
        'color': AppTheme.pinkLanguage,
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TRAINER PROFILE',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      SoundService.instance.isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: AppTheme.primaryNeon,
                    ),
                    onPressed: () {
                      setState(() {
                        SoundService.instance.toggleMute();
                      });
                    },
                  ),
                ],
              ).animate().fadeIn(),

              const SizedBox(height: 20),

              // Hero Trainer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.surfaceCardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryNeon.withValues(alpha: 0.08),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNeon.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 36,
                        backgroundColor: AppTheme.surfaceCard,
                        child: Text(
                          '🧠',
                          style: TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          profile!.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _showEditNameDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: AppTheme.primaryNeon,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile!.email,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        titleRank.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).scale(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // Overview Stats Grid
              Row(
                children: [
                  _profileStatTile('OVERALL BPI', '${profile!.overallBpi}',
                      Icons.psychology, AppTheme.purpleMemory),
                  const SizedBox(width: 12),
                  _profileStatTile('WORKOUTS', '${profile!.totalWorkoutsCompleted}',
                      Icons.fitness_center, AppTheme.primaryNeon),
                ],
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Row(
                children: [
                  _profileStatTile('CURRENT STREAK', '${profile!.currentStreak}d 🔥',
                      Icons.local_fire_department, AppTheme.amberProblemSolving),
                  const SizedBox(width: 12),
                  _profileStatTile('BEST STREAK', '${profile!.bestStreak}d 🏆',
                      Icons.emoji_events, AppTheme.coralFlexibility),
                ],
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 28),

              // Achievements Section Header
              const Text(
                'ACHIEVEMENTS & BADGES',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 14),

              // Achievements Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final ach = achievements[index];
                  bool unlocked = ach['unlocked'] as bool;
                  Color color = ach['color'] as Color;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: unlocked
                            ? color.withValues(alpha: 0.5)
                            : AppTheme.surfaceCardBorder,
                      ),
                      boxShadow: unlocked
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.1),
                                blurRadius: 10,
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: unlocked
                                    ? color.withValues(alpha: 0.15)
                                    : AppTheme.bgDark,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                ach['icon'],
                                size: 20,
                                color: unlocked ? color : AppTheme.textMuted,
                              ),
                            ),
                            Icon(
                              unlocked
                                  ? Icons.check_circle_rounded
                                  : Icons.lock_rounded,
                              size: 16,
                              color: unlocked
                                  ? AppTheme.emeraldAttention
                                  : AppTheme.textMuted,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ach['title'],
                              style: TextStyle(
                                color: unlocked
                                    ? AppTheme.textPrimary
                                    : AppTheme.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ach['desc'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 28),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppTheme.coralFlexibility, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded,
                      color: AppTheme.coralFlexibility, size: 20),
                  label: const Text(
                    'LOGOUT ACCOUNT',
                    style: TextStyle(
                      color: AppTheme.coralFlexibility,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileStatTile(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.surfaceCardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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
