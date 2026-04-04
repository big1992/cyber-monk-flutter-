import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';

class GameHud extends StatelessWidget {
  final CyberMonkGame game;

  const GameHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: game.karmaSystem,
      builder: (context, child) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Health Text & Pause Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Health: ${game.player.health.toInt()} / ${game.player.maxHealth.toInt()}",
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.pause, color: Colors.cyanAccent),
                        onPressed: () {
                          if (!game.overlays.isActive('PauseMenu')) {
                            game.pauseEngine();
                            game.overlays.add('PauseMenu');
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  
                  // Karma Bar (-100 to 100)
                  const Text("Karma Alignment", style: TextStyle(color: Colors.white, fontSize: 14)),
                  Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30, width: 1),
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurpleAccent, Colors.grey, Colors.yellowAccent],
                          ),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      Positioned(
                        left: 0, right: 0,
                        child: Center(
                          child: Container(width: 2, height: 14, color: Colors.red),
                        ),
                      ),
                      Positioned(
                        left: (MediaQuery.of(context).size.width - 32) * ((game.karmaSystem.karma + 100) / 200) - 5,
                        child: Container(
                          width: 14, height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.cyanAccent, 
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.cyan, blurRadius: 4)]
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // EXP Bar
                  Text("Level: ${game.karmaSystem.level} | Wave: ${game.currentWave}", style: const TextStyle(color: Colors.white)),
                  LinearProgressIndicator(
                    value: game.karmaSystem.exp / game.karmaSystem.expToNextLevel,
                    backgroundColor: Colors.blueGrey,
                    color: Colors.lightBlueAccent,
                  ),
                ],
              ),
            ),
            
            // Ultimate Button / Gauge (Bottom Right)
            Positioned(
              bottom: 30,
              right: 30,
              child: Stack(
                alignment: Alignment.center,
                children: [
                   SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: game.player.ultimateCharge / game.player.maxUltimateCharge,
                        strokeWidth: 6,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          game.player.ultimateCharge >= game.player.maxUltimateCharge ? Colors.cyanAccent : Colors.grey
                        ),
                      ),
                   ),
                   if (game.player.ultimateCharge >= game.player.maxUltimateCharge)
                     FloatingActionButton(
                        onPressed: () {
                           game.activateUltimate();
                        },
                        backgroundColor: Colors.cyan,
                        child: const Icon(Icons.flash_on, color: Colors.black, size: 36),
                     )
                   else
                     const Icon(Icons.flash_off, color: Colors.white30, size: 28),
                ]
              )
            ),
          ],
        );
      },
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final CyberMonkGame game;

  const GameOverOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "GAME OVER",
              style: TextStyle(color: Colors.redAccent, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                game.resetGame();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
              child: const Text("RETURN TO TITLE"),
            ),
          ],
        ),
      ),
    );
  }
}
