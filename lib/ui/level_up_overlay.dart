import 'dart:math';
import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import '../data/skills.dart';

class LevelUpOverlay extends StatefulWidget {
  final CyberMonkGame game;

  const LevelUpOverlay({super.key, required this.game});

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay> {
  late List<SkillData> offeredSkills;

  @override
  void initState() {
    super.initState();
    _rollSkills();
  }

  void _rollSkills() {
    final rng = Random();
    // Assuming there are at least 3 skills in allSkills
    var pool = List<SkillData>.from(allSkills);
    pool.shuffle(rng);
    offeredSkills = pool.take(3).toList();
  }

  void _selectSkill(SkillData skill) {
    skill.applyEffect(widget.game.player);
    widget.game.player.acquiredSkills.add(skill);
    widget.game.karmaSystem.consumeLevelUp();

    if (widget.game.karmaSystem.pendingLevelUps > 0) {
      // Re-roll for next pending level up
      setState(() { _rollSkills(); });
    } else {
      // All level ups consumed — close overlay and resume
      widget.game.overlays.remove('LevelUp');
      widget.game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87, // Semi-transparent dark background
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "LEVEL UP!",
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Choose a Cyber-Sutra",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 40),
          // Skill Cards
          Expanded(
            child: ListView.separated(
              itemCount: offeredSkills.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final skill = offeredSkills[index];
                
                // Color coding by alignment
                Color cardBorder;
                Color iconColor;
                Color cardBg;
                if (skill.alignment == SkillAlignment.light) {
                  cardBorder = Colors.white;
                  iconColor = Colors.yellowAccent;
                  cardBg = Colors.yellow.withOpacity(0.05);
                } else if (skill.alignment == SkillAlignment.dark) {
                  cardBorder = Colors.purpleAccent;
                  iconColor = Colors.redAccent;
                  cardBg = Colors.purple.withOpacity(0.15); // Make it stand out from black background
                } else {
                  cardBorder = Colors.blueAccent;
                  iconColor = Colors.cyanAccent;
                  cardBg = Colors.blue.withOpacity(0.05);
                }

                return GestureDetector(
                  onTap: () => _selectSkill(skill),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      border: Border.all(color: cardBorder, width: 2),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: cardBorder.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(skill.icon, color: iconColor, size: 40),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                skill.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                skill.description,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
