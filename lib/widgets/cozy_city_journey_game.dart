import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../models/game_result.dart';
import '../models/level_data.dart';
import '../models/user_level_progress.dart';

/// Flame Game rendering a living Clash-Style Village World around the Main Cognitive Journey Path.
class CozyCityJourneyGame extends FlameGame with TapCallbacks {
  final List<UnitData> units;
  UserLevelProgress? levelProgress;
  final Function(PuzzleLevel level) onLevelSelected;

  double currentScrollOffset = 0.0;
  final List<_VillageSparkle> _sparkles = [];
  final math.Random _rnd = math.Random();

  late ClashVillageMapComponent _mapComponent;
  late AnimatedVillagersComponent _villagersComponent;

  CozyCityJourneyGame({
    required this.units,
    required this.levelProgress,
    required this.onLevelSelected,
  });

  @override
  Color backgroundColor() => const Color(0xFF357A1E); // Clash of Clans vibrant grass green

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _mapComponent = ClashVillageMapComponent(
      units: units,
      progress: levelProgress,
    );
    _villagersComponent = AnimatedVillagersComponent();

    add(_mapComponent);
    add(_villagersComponent);
  }

  void updateData(UserLevelProgress newProgress, double scrollOffset) {
    levelProgress = newProgress;
    currentScrollOffset = scrollOffset;
    _mapComponent.progress = newProgress;
    _mapComponent.scrollOffset = scrollOffset;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    final tapPos = event.canvasPosition;

    final hitLevel = _mapComponent.checkBuildingTap(tapPos);
    if (hitLevel != null) {
      onLevelSelected(hitLevel);
      // Spawn golden elixir sparkles on tap
      for (int i = 0; i < 10; i++) {
        _sparkles.add(_VillageSparkle(
          x: tapPos.x + (_rnd.nextDouble() * 24 - 12),
          y: tapPos.y + (_rnd.nextDouble() * 24 - 12),
          color: const Color(0xFFFFD700),
          size: _rnd.nextDouble() * 5 + 3,
          vx: (_rnd.nextDouble() - 0.5) * 70,
          vy: (_rnd.nextDouble() - 0.5) * 70,
          life: 0.8,
        ));
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (int i = _sparkles.length - 1; i >= 0; i--) {
      _sparkles[i].update(dt);
      if (_sparkles[i].life <= 0) {
        _sparkles.removeAt(i);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final p in _sparkles) {
      p.render(canvas);
    }
  }
}

// ==========================================
// CLASH VILLAGE MAP COMPONENT
// ==========================================
class ClashVillageMapComponent extends Component with HasGameReference<CozyCityJourneyGame> {
  final List<UnitData> units;
  UserLevelProgress? progress;
  double scrollOffset = 0.0;
  double _animTime = 0.0;

  final math.Random _rnd = math.Random(123);
  final Map<String, Offset> _buildingPositions = {};
  final List<_SideVillageStructure> _sideStructures = [];

  ClashVillageMapComponent({
    required this.units,
    required this.progress,
  }) {
    _generateSideVillageStructures();
  }

  void _generateSideVillageStructures() {
    for (int i = 0; i < 45; i++) {
      _sideStructures.add(_SideVillageStructure(
        sideXOffset: (i % 2 == 0 ? -1.0 : 1.0) * (0.65 + _rnd.nextDouble() * 0.35),
        levelIndexRatio: i / 45.0,
        type: _StructureType.values[i % _StructureType.values.length],
      ));
    }
  }

  PuzzleLevel? checkBuildingTap(Vector2 tapPos) {
    for (final entry in _buildingPositions.entries) {
      Offset pos = entry.value;
      double screenY = pos.dy - scrollOffset;
      if ((tapPos.x - pos.dx).abs() < 44 && (tapPos.y - screenY).abs() < 44) {
        for (var u in units) {
          for (var l in u.levels) {
            if (l.id == entry.key) return l;
          }
        }
      }
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _animTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final size = game.size;
    if (size.x <= 0 || size.y <= 0) return;

    double cX = size.x / 2;
    double startY = 120.0 - scrollOffset;
    int activeLevelNum = progress?.highestUnlockedLevelIndex ?? 1;

    // 1. CHECKERED CLASH VILLAGE GRASS TERRAIN
    _renderCheckeredGrass(canvas, size);

    // Compute main road points & side branch coordinates
    List<Offset> mainRoadPoints = [];
    List<List<Offset>> sideBranchPaths = [];
    int totalIndex = 0;

    for (var unit in units) {
      for (var level in unit.levels) {
        double nodeX = cX + (level.xOffset * (size.x * 0.32));
        double nodeY = startY + (totalIndex * 140.0);
        Offset mainPos = Offset(nodeX, nodeY);
        mainRoadPoints.add(mainPos);
        _buildingPositions[level.id] = Offset(nodeX, startY + (totalIndex * 140.0));

        // Side branch paths extending left/right to side huts/gardens
        double branchDirection = (totalIndex % 2 == 0) ? -1.0 : 1.0;
        Offset branchEnd = Offset(
          nodeX + (branchDirection * (size.x * 0.28)),
          nodeY + ((totalIndex % 3 - 1) * 25.0),
        );
        sideBranchPaths.add([mainPos, branchEnd]);

        totalIndex++;
      }
    }

    // 2. DRAW SECONDARY BRANCHING VILLAGE PATHS
    _renderSecondaryBranchPaths(canvas, sideBranchPaths);

    // 3. DRAW MAIN JOURNEY ROAD (DUOLINGO-STYLE GAMEPLAY ROUTE)
    if (mainRoadPoints.length >= 2) {
      _renderMainJourneyRoad(canvas, mainRoadPoints);
    }

    // 4. DRAW DOMAIN-THEMED SQUIRCLE BUILDINGS ON MAIN JOURNEY
    totalIndex = 0;
    for (var unit in units) {
      for (var level in unit.levels) {
        Offset pos = mainRoadPoints[totalIndex];
        bool isUnlocked = progress?.isLevelUnlocked(level.levelNumber) ?? false;
        bool isActive = isUnlocked && level.levelNumber == activeLevelNum;
        int stars = progress?.levelStars[level.id] ?? 0;
        bool isChestOpened = progress?.openedChests.contains(level.id) ?? false;

        _drawDomainSquircleBuildingNode(
          canvas: canvas,
          pos: pos,
          level: level,
          unitColor: unit.themeColor,
          isUnlocked: isUnlocked,
          isActive: isActive,
          stars: stars,
          isChestOpened: isChestOpened,
        );

        totalIndex++;
      }
    }

    // 5. DRAW SIDE VILLAGE STRUCTURES & DECORATIONS ALONG BRANCH PATHS
    double mapTotalHeight = (totalIndex * 140.0);
    for (final struct in _sideStructures) {
      double structY = startY + (struct.levelIndexRatio * mapTotalHeight);
      double structX = cX + (struct.sideXOffset * (size.x * 0.42));

      // Calculate unlock state based on Y position progression
      int levelNumberAtY = (struct.levelIndexRatio * totalIndex).floor() + 1;
      bool isUnlocked = levelNumberAtY <= activeLevelNum;

      if (structY > -80 && structY < size.y + 80) {
        _drawSideVillageStructure(canvas, structX, structY, struct.type, isUnlocked);
      }
    }
  }

  void _renderCheckeredGrass(Canvas canvas, Vector2 size) {
    final grass1 = Paint()..color = const Color(0xFF357A1E);
    final grass2 = Paint()..color = const Color(0xFF428E25);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), grass1);

    double tileSize = 55.0;
    int cols = (size.x / tileSize).ceil() + 1;
    int rows = (size.y / tileSize).ceil() + 1;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c) % 2 == 1) {
          canvas.drawRect(
            Rect.fromLTWH(c * tileSize, r * tileSize, tileSize, tileSize),
            grass2,
          );
        }
      }
    }
  }

  void _renderSecondaryBranchPaths(Canvas canvas, List<List<Offset>> branches) {
    final branchBorder = Paint()
      ..color = const Color(0xFF4A341E)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final branchDirt = Paint()
      ..color = const Color(0xFF7A5531) // Side dirt path
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final b in branches) {
      if (b.length == 2) {
        canvas.drawLine(b[0], b[1], branchBorder);
        canvas.drawLine(b[0], b[1], branchDirt);
      }
    }
  }

  void _renderMainJourneyRoad(Canvas canvas, List<Offset> points) {
    final outerBorder = Paint()
      ..color = const Color(0xFF4A341E)
      ..strokeWidth = 38
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final innerDirt = Paint()
      ..color = const Color(0xFF8C6239) // Main Clash avenue
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dashStones = Paint()
      ..color = const Color(0xFFFFB703).withValues(alpha: 0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      Offset p1 = points[i];
      Offset p2 = points[i + 1];
      double midY = (p1.dy + p2.dy) / 2;
      path.cubicTo(p1.dx, midY, p2.dx, midY, p2.dx, p2.dy);
    }

    canvas.drawPath(path, outerBorder);
    canvas.drawPath(path, innerDirt);
    canvas.drawPath(path, dashStones);
  }

  void _drawDomainSquircleBuildingNode({
    required Canvas canvas,
    required Offset pos,
    required PuzzleLevel level,
    required Color unitColor,
    required bool isUnlocked,
    required bool isActive,
    required int stars,
    required bool isChestOpened,
  }) {
    double x = pos.dx;
    double y = pos.dy;
    double bSize = level.type == LevelType.boss ? 68 : 58;

    // 3D Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + 3, y + 7), width: bSize, height: bSize),
        const Radius.circular(20),
      ),
      shadowPaint,
    );

    // Bevel Outer Wood/Gold Border
    Color borderColor = !isUnlocked
        ? const Color(0xFF38352F)
        : level.type == LevelType.boss
            ? const Color(0xFFFFD700)
            : const Color(0xFF7A4E21);

    final borderPaint = Paint()..color = borderColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y + 2), width: bSize, height: bSize),
        const Radius.circular(20),
      ),
      borderPaint,
    );

    // Domain Specific Colors
    Color domainColor = _getDomainColor(level.domain);
    Color roofColor = !isUnlocked ? const Color(0xFF4A4640) : domainColor;

    final roofPaint = Paint()..color = roofColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y - 2), width: bSize - 8, height: bSize - 8),
        const Radius.circular(16),
      ),
      roofPaint,
    );

    // Inner Domain Roof Badge / Emblem
    if (isUnlocked) {
      final innerGlow = Paint()..color = Colors.white.withValues(alpha: 0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y - 2), width: bSize - 22, height: bSize - 22),
          const Radius.circular(10),
        ),
        innerGlow,
      );
    }

    // Lock Icon for Locked Buildings
    if (!isUnlocked) {
      final lockPaint = Paint()
        ..color = const Color(0xFFA0AEC0)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(x, y - 4), 6, lockPaint);
      canvas.drawRect(Rect.fromCenter(center: Offset(x, y + 2), width: 12, height: 8), Paint()..color = const Color(0xFFA0AEC0));
    }

    // Active Character Brain Avatar on Main Road (Idle Breathing Bobbing)
    if (isActive) {
      double bobY = math.sin(_animTime * 4.0) * 3.0; // Gentle idle breathing bob
      _drawIdleBrainAvatar(canvas, x, y - 44 + bobY);
    }
  }

  Color _getDomainColor(CognitiveDomain domain) {
    switch (domain) {
      case CognitiveDomain.memory:
        return const Color(0xFF9B72CF); // Lavender Library
      case CognitiveDomain.speed:
        return const Color(0xFF38BDF8); // Cyan Speed Arena
      case CognitiveDomain.attention:
        return const Color(0xFF34D399); // Emerald Watchtower
      case CognitiveDomain.flexibility:
        return const Color(0xFFFF758F); // Rose Academy
      case CognitiveDomain.problemSolving:
        return const Color(0xFFF59E0B); // Amber Workshop
    }
  }

  void _drawIdleBrainAvatar(Canvas canvas, double x, double y) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(x, y + 14), 14, shadowPaint);

    final avatarPaint = Paint()..color = const Color(0xFFFFD700);
    canvas.drawCircle(Offset(x, y), 16, avatarPaint);

    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(x - 4, y - 4), 4, eyePaint);
    canvas.drawCircle(Offset(x + 4, y - 4), 4, eyePaint);

    final pupilPaint = Paint()..color = Colors.black;
    canvas.drawCircle(Offset(x - 4, y - 4), 2, pupilPaint);
    canvas.drawCircle(Offset(x + 4, y - 4), 2, pupilPaint);
  }

  void _drawSideVillageStructure(Canvas canvas, double x, double y, _StructureType type, bool isUnlocked) {
    double alpha = isUnlocked ? 1.0 : 0.45;

    switch (type) {
      case _StructureType.cozyHouse:
        final shadow = Paint()
          ..color = Colors.black.withValues(alpha: 0.3 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawRect(Rect.fromLTWH(x - 14, y - 10, 32, 28), shadow);

        final roofPaint = Paint()..color = (isUnlocked ? const Color(0xFFC05621) : const Color(0xFF5A524A)).withValues(alpha: alpha);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 16, y - 14, 32, 28), const Radius.circular(6)),
          roofPaint,
        );

        if (isUnlocked) {
          final winPaint = Paint()..color = const Color(0xFFFFD166).withValues(alpha: 0.9);
          canvas.drawRect(Rect.fromLTWH(x - 8, y - 6, 6, 8), winPaint);
          canvas.drawRect(Rect.fromLTWH(x + 2, y - 6, 6, 8), winPaint);
        }
        break;

      case _StructureType.woodenHut:
        final hutPaint = Paint()..color = (isUnlocked ? const Color(0xFF7A4E21) : const Color(0xFF4A3B2B)).withValues(alpha: alpha);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 14, y - 12, 28, 24), const Radius.circular(5)),
          hutPaint,
        );
        break;

      case _StructureType.watchtower:
        final towerPaint = Paint()..color = (isUnlocked ? const Color(0xFF2B6CB0) : const Color(0xFF384352)).withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), 14, towerPaint);
        break;

      case _StructureType.pond:
        final pondPaint = Paint()..color = const Color(0xFF3182CE).withValues(alpha: 0.8 * alpha);
        canvas.drawOval(Rect.fromLTWH(x - 18, y - 12, 36, 24), pondPaint);
        final lilyPaint = Paint()..color = const Color(0xFF38A169).withValues(alpha: alpha);
        canvas.drawCircle(Offset(x - 4, y - 2), 4, lilyPaint);
        break;

      case _StructureType.gardenPatch:
        final gardenPaint = Paint()..color = (isUnlocked ? const Color(0xFFD53F8C) : const Color(0xFF6B4B5E)).withValues(alpha: alpha);
        canvas.drawCircle(Offset(x - 6, y), 5, gardenPaint);
        canvas.drawCircle(Offset(x + 6, y), 5, gardenPaint);
        canvas.drawCircle(Offset(x, y - 6), 5, gardenPaint);
        break;

      case _StructureType.resourcePile:
        final woodPaint = Paint()..color = (isUnlocked ? const Color(0xFFD69E2E) : const Color(0xFF635233)).withValues(alpha: alpha);
        canvas.drawRect(Rect.fromLTWH(x - 10, y - 6, 20, 12), woodPaint);
        break;

      case _StructureType.lanternPost:
        final postPaint = Paint()..color = const Color(0xFF2D3748);
        canvas.drawCircle(Offset(x, y), 3, postPaint);
        if (isUnlocked) {
          final aura = Paint()
            ..color = const Color(0xFFFFD166).withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
          canvas.drawCircle(Offset(x, y), 14, aura);
        }
        break;
    }
  }
}

enum _StructureType { cozyHouse, woodenHut, watchtower, pond, gardenPatch, resourcePile, lanternPost }

class _SideVillageStructure {
  final double sideXOffset;
  final double levelIndexRatio;
  final _StructureType type;

  _SideVillageStructure({
    required this.sideXOffset,
    required this.levelIndexRatio,
    required this.type,
  });
}

// ==========================================
// ANIMATED VILLAGERS COMPONENT
// ==========================================
class AnimatedVillagersComponent extends Component with HasGameReference<CozyCityJourneyGame> {
  final List<_Villager> _villagers = [];
  final math.Random _rnd = math.Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (int i = 0; i < 8; i++) {
      _villagers.add(_Villager(
        x: _rnd.nextDouble() * 350,
        y: _rnd.nextDouble() * 1500,
        speed: _rnd.nextDouble() * 14 + 10,
        color: i % 3 == 0
            ? const Color(0xFFE53E3E)
            : i % 3 == 1
                ? const Color(0xFF3182CE)
                : const Color(0xFFDD6B20),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final size = game.size;
    for (final v in _villagers) {
      v.x += math.sin(v.y * 0.05) * 0.8;
      v.y += v.speed * dt * v.direction;

      if (v.y > size.y + 2000 || v.y < -200) {
        v.direction *= -1;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final v in _villagers) {
      double screenY = v.y - game.currentScrollOffset * 0.8;
      if (screenY > -20 && screenY < game.size.y + 20) {
        final villagerPaint = Paint()..color = v.color;
        canvas.drawCircle(Offset(v.x, screenY), 5, villagerPaint);
        final hatPaint = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(v.x, screenY - 2), 2.5, hatPaint);
      }
    }
  }
}

class _Villager {
  double x;
  double y;
  double speed;
  double direction = 1.0;
  Color color;

  _Villager({required this.x, required this.y, required this.speed, required this.color});
}

class _VillageSparkle {
  double x;
  double y;
  Color color;
  double size;
  double vx;
  double vy;
  double life;

  _VillageSparkle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.vx,
    required this.vy,
    required this.life,
  });

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt * 1.5;
  }

  void render(Canvas canvas) {
    if (life <= 0) return;
    final paint = Paint()..color = color.withValues(alpha: life.clamp(0.0, 1.0));
    canvas.drawCircle(Offset(x, y), size * life, paint);
  }
}
