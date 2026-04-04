import 'package:flutter/material.dart';
import '../game/cyber_monk_game.dart';
import '../data/save_system.dart';
import '../systems/audio_system.dart';

class UpgradesOverlay extends StatefulWidget {
  final CyberMonkGame game;

  const UpgradesOverlay({super.key, required this.game});

  @override
  State<UpgradesOverlay> createState() => _UpgradesOverlayState();
}

class _UpgradesOverlayState extends State<UpgradesOverlay> {
  final int hpCost = 10;
  final int dmgCost = 15;

  void _upgradeHealth() async {
    if (SaveSystem.currentCrystals >= hpCost) {
      await SaveSystem.spendCrystals(hpCost);
      await SaveSystem.upgradeHealth();
      AudioSystem.playSFX('upgrade.wav', volume: 0.8);
      setState(() {});
    }
  }

  void _upgradeDamage() async {
    if (SaveSystem.currentCrystals >= dmgCost) {
      await SaveSystem.spendCrystals(dmgCost);
      await SaveSystem.upgradeDamage();
      AudioSystem.playSFX('upgrade.wav', volume: 0.8);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "THE DOJO",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 50,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Karma Crystals: ${SaveSystem.currentCrystals} 💎",
              style: const TextStyle(color: Colors.yellowAccent, fontSize: 24),
            ),
            const SizedBox(height: 40),
            
            // HP Upgrade
            _buildUpgradeCard(
              "Max Health",
              "Increase starting health by +10.",
              "Current: +${SaveSystem.upgradedMaxHealth}",
              hpCost,
              _upgradeHealth,
              SaveSystem.currentCrystals >= hpCost,
              Colors.greenAccent,
            ),
            
            const SizedBox(height: 20),
            
            // DMG Upgrade
            _buildUpgradeCard(
              "Base Damage",
              "Increase projectile damage by +1.",
              "Current: +${SaveSystem.upgradedBaseDamage}",
              dmgCost,
              _upgradeDamage,
              SaveSystem.currentCrystals >= dmgCost,
              Colors.redAccent,
            ),
            
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                widget.game.overlays.remove('Upgrades');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white24,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: const Text("BACK TO MENU", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(String title, String desc, String currentStat, int cost, VoidCallback onBuy, bool canAfford, Color iconColor) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: canAfford ? iconColor : Colors.white24),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: iconColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 5),
          Text(currentStat, style: const TextStyle(color: Colors.cyanAccent, fontSize: 14)),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: canAfford ? onBuy : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? iconColor.withOpacity(0.8) : Colors.grey.withOpacity(0.5),
            ),
            child: Text(
              "UPGRADE ($cost 💎)", 
              style: TextStyle(color: canAfford ? Colors.black : Colors.white54, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
}
