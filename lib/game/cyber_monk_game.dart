import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import '../components/player.dart';
import '../components/enemy.dart';
import '../components/boss.dart';
import '../systems/karma_system.dart';
import '../data/save_system.dart';
import '../systems/audio_system.dart';
import '../components/ultimate_effect.dart';
import '../components/bullet.dart';

class CyberMonkGame extends FlameGame with PanDetector, HasCollisionDetection {
  late Player player;
  final KarmaSystem karmaSystem = KarmaSystem();
  int currentWave = 1;
  double waveTimer = 0;
  final Random rng = Random();

  // Core system
  bool isGameStarted = false;

  // Boss system
  bool bossAlive = false;
  bool bossWarningShown = false;
  int nextBossWave = 5; // First boss at wave 5, then every 5 waves

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    player = Player(
      position: Vector2(size.x / 2, size.y - 100),
    );
    // Apply permanent Dojo upgrades
    player.maxHealth += SaveSystem.upgradedMaxHealth;
    player.health = player.maxHealth;
    player.baseDamage += SaveSystem.upgradedBaseDamage;
    add(player);

    karmaSystem.addListener(_onKarmaChanged);
  }

  void _onKarmaChanged() {}

  @override
  void update(double dt) {
    super.update(dt);
    if (!isGameStarted) return;

    if (player.isDead) {
      if (!overlays.isActive('GameOver')) {
        overlays.add('GameOver');
        overlays.remove('HUD');
        pauseEngine();
      }
      return;
    }

    if (karmaSystem.pendingLevelUps > 0) {
      if (!overlays.isActive('LevelUp')) {
        overlays.add('LevelUp');
        pauseEngine();
      }
      return;
    }

    _spawnEnemies(dt);
  }

  void _spawnEnemies(double dt) {
    // Skip normal spawning when boss is alive
    if (bossAlive) return;

    waveTimer += dt;
    double spawnRate = max(0.5, 2.0 - (currentWave * 0.1));
    if (waveTimer >= spawnRate) {
      waveTimer = 0;

      // Check if it's time for a boss
      if (currentWave >= nextBossWave && !bossWarningShown) {
        _triggerBossWarning();
        return;
      }

      double startX = rng.nextDouble() * size.x;
      startX = startX.clamp(20, size.x - 20);

      EnemyType type = rng.nextDouble() > 0.8 ? EnemyType.ninja : EnemyType.scrapper;
      if (currentWave > 5 && rng.nextDouble() > 0.9) {
        type = EnemyType.tank;
      } else if (currentWave > 2 && rng.nextDouble() > 0.85) {
        type = EnemyType.kamikaze;
      } else if (currentWave > 3 && rng.nextDouble() > 0.9) {
        type = EnemyType.turret;
        // Turrets spawn at the very top edge
        startX = rng.nextDouble() > 0.5 ? 20.0 : size.x - 20.0;
      }

      add(Enemy(
        position: Vector2(startX, -50),
        type: type,
        waveMultiplier: 1.0 + (currentWave * 0.2),
      ));

      if (rng.nextDouble() > 0.95) currentWave++;
    }
  }

  void _triggerBossWarning() {
    bossWarningShown = true;
    AudioSystem.playSFX('boss.wav');
    // Clear all current enemies
    removeWhere((c) => c is Enemy);

    if (!overlays.isActive('BossWarning')) {
      overlays.add('BossWarning');
    }
  }

  void spawnBoss() {
    overlays.remove('BossWarning');
    bossAlive = true;
    add(Boss(
      position: Vector2(size.x / 2, -80),
      waveNumber: currentWave,
    ));
  }

  void onBossDead() {
    SaveSystem.addCrystals(10); // Reward for boss kill
    
    bossAlive = false;
    bossWarningShown = false;
    currentWave += 2; // Advance waves after boss kill
    nextBossWave = currentWave + 5; // Next boss in 5 more waves
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!isGameStarted) return;
    
    if (!player.isDead) {
      player.position.add(info.delta.global * player.speedMultiplier);
      player.position.x = player.position.x.clamp(player.size.x / 2, size.x - player.size.x / 2);
      player.position.y = player.position.y.clamp(player.size.y / 2, size.y - player.size.y / 2);
    }
  }

  void startGame() {
    isGameStarted = true;
    overlays.remove('MainMenu');
    overlays.add('HUD');
    AudioSystem.playBGM('bgm.mp3');
  }

  void resetGame() {
    AudioSystem.stopBGM();
    children.forEach((c) {
      if (c != player) remove(c);
    });

    player.reset(Vector2(size.x / 2, size.y - 100));
    karmaSystem.reset();
    currentWave = 1;
    waveTimer = 0;
    bossAlive = false;
    bossWarningShown = false;
    nextBossWave = 5;
    isGameStarted = false; // Need to ensure it's false for main menu
    
    resumeEngine();
    overlays.remove('GameOver');
    overlays.remove('LevelUp');
    overlays.remove('BossWarning');
    overlays.remove('HUD');
    overlays.remove('PauseMenu');
    overlays.add('MainMenu');
  }

  void activateUltimate() {
    if (player.ultimateCharge < player.maxUltimateCharge || !isGameStarted || player.isDead) return;

    player.ultimateCharge = 0;
    karmaSystem.notifyListeners();

    // 1. Wipe hostile bullets
    for (final bullet in children.whereType<Bullet>()) {
      if (!bullet.isPlayerOwned) {
        bullet.removeFromParent();
      }
    }

    // 2. Deal massive damage to enemies
    final enemies = children.whereType<Enemy>().toList();
    for (final enemy in enemies) {
      if (!enemy.isDead) enemy.takeDamage(250.0);
    }

    // 3. Deal massive damage to boss
    final bosses = children.whereType<Boss>().toList();
    for (final boss in bosses) {
      if (!boss.isDead) boss.takeDamage(250.0);
    }

    // 4. VFX and SFX
    AudioSystem.playSFX('explode.wav', volume: 1.0);
    
    // Play screen shake effect manually
    camera.viewfinder.add(
      MoveByEffect(
        Vector2(15, 15),
        RepeatedEffectController(
          SequenceEffectController([
            LinearEffectController(0.05),
            ReverseLinearEffectController(0.05),
          ]), 
          10
        ),
      )
    );

    // 5. Spawn Ultimate Effect (Cyan Wave)
    add(UltimateEffect(position: size / 2));
    
    // 6. Give player brief safety
    player.currentInvulnTimer += 2.0;
  }
}
