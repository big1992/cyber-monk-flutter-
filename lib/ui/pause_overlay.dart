import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import '../data/skills.dart';

class PauseMenuOverlay extends StatelessWidget {
  final CyberMonkGame game;

  const PauseMenuOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    // Group skills by name to show "SkillName x2"
    final Map<String, int> skillCounts = {};
    final Map<String, SkillData> skillRefs = {};

    for (var skill in game.player.acquiredSkills) {
      skillCounts[skill.name] = (skillCounts[skill.name] ?? 0) + 1;
      skillRefs[skill.name] = skill;
    }

    final uniqueSkills = skillCounts.keys.toList();

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          const Text(
            "PAUSED",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 20),
          
          ElevatedButton(
            onPressed: () {
              game.overlays.remove('PauseMenu');
              game.resumeEngine();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text("RESUME GAME", style: TextStyle(fontSize: 18, color: Colors.black)),
          ),
          
          const SizedBox(height: 30),
          const Text(
            "ACQUIRED CYBER-SUTRAS",
            style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),

          Expanded(
            child: uniqueSkills.isEmpty 
              ? const Center(child: Text("No skills acquired yet.", style: TextStyle(color: Colors.white54)))
              : ListView.separated(
                  itemCount: uniqueSkills.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 15),
                  itemBuilder: (context, index) {
                    final skillName = uniqueSkills[index];
                    final count = skillCounts[skillName]!;
                    final skill = skillRefs[skillName]!;
                    
                    Color iconColor;
                    if (skill.alignment == SkillAlignment.light) {
                      iconColor = Colors.yellowAccent;
                    } else if (skill.alignment == SkillAlignment.dark) {
                      iconColor = Colors.redAccent;
                    } else {
                      iconColor = Colors.cyanAccent;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(skill.icon, color: iconColor, size: 30),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      skill.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    if (count > 1) ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.cyanAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text("x$count", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                      ),
                                    ]
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  skill.description,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
