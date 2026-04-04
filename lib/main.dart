import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/cyber_monk_game.dart';
import 'ui/hud.dart';
import 'ui/boss_warning_overlay.dart';
import 'ui/main_menu_overlay.dart';
import 'ui/pause_overlay.dart';
import 'ui/upgrades_overlay.dart';
import 'ui/level_up_overlay.dart';
import 'data/save_system.dart';
import 'systems/audio_system.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SaveSystem.initialize();
  await AudioSystem.initialize();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450), // Max mobile width
            child: AspectRatio(
              aspectRatio: 9 / 16, // Typical mobile portrait ratio
              child: ClipRect(
                child: GameWidget<CyberMonkGame>(
                  game: CyberMonkGame(),
                  overlayBuilderMap: {
                    'HUD': (context, game) => GameHud(game: game),
                    'GameOver': (context, game) => GameOverOverlay(game: game),
                    'LevelUp': (context, game) => LevelUpOverlay(game: game),
                    'BossWarning': (context, game) => BossWarningOverlay(
                      onComplete: () => (game as CyberMonkGame).spawnBoss(),
                    ),
                    'PauseMenu': (context, game) => PauseMenuOverlay(game: game),
                    'MainMenu': (context, game) => MainMenuOverlay(game: game),
                    'Upgrades': (context, game) => UpgradesOverlay(game: game),
                  },
                  initialActiveOverlays: const ['MainMenu'],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
