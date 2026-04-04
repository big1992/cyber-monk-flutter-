import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';

class MainMenuOverlay extends StatefulWidget {
  final CyberMonkGame game;

  const MainMenuOverlay({super.key, required this.game});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    widget.game.startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            const Text(
              'CYBER MONK',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 64,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                letterSpacing: 8,
                shadows: [
                  Shadow(color: Colors.cyan, blurRadius: 20),
                  Shadow(color: Colors.blueAccent, blurRadius: 40),
                ],
              ),
            ),
            const Text(
              'BULLET KARMA',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontSize: 32,
                fontFamily: 'Courier',
                fontWeight: FontWeight.w900,
                letterSpacing: 12,
                shadows: [
                  Shadow(color: Colors.purple, blurRadius: 20),
                ],
              ),
            ),
            const SizedBox(height: 80),

            // Start Button
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return GestureDetector(
                  onTap: _startGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.yellowAccent.withOpacity(0.5 + 0.5 * _pulseController.value),
                        width: 2 + 2 * _pulseController.value,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.yellowAccent.withOpacity(0.2 * _pulseController.value),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      'TAP TO START',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.yellowAccent,
                            blurRadius: 10 * _pulseController.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                widget.game.overlays.add('Upgrades');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white12,
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("DOJO UPGRADES", style: TextStyle(color: Colors.cyanAccent, fontSize: 18, letterSpacing: 2)),
            ),
            
            const SizedBox(height: 40),
            const Text(
              'A neon-lit roguelike meditation',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
