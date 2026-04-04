import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioSystem {
  static bool _initialized = false;
  static bool bgmEnabled = true;
  static bool sfxEnabled = true;

  static final Map<String, int> _lastPlayedMap = {};

  // AudioPool — works on Web AND native. Initialized lazily after user gesture.
  static final Map<String, AudioPool> _pools = {};
  static bool _poolsReady = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await FlameAudio.audioCache.loadAll([
        'bgm.mp3',
        'shoot.wav',
        'hit.wav',
        'explode.wav',
        'reward.wav',
        'boss.wav',
        'upgrade.wav',
      ]);
      FlameAudio.bgm.initialize();
      _initialized = true;
    } catch (e) {
      print("AudioSystem init error: $e");
      _initialized = true;
    }
  }

  /// Call this AFTER the first user interaction (e.g. in startGame())
  /// so that Web Audio Context is already unlocked by the browser.
  static Future<void> initPools() async {
    if (_poolsReady) return;
    try {
      _pools['shoot.wav'] = await FlameAudio.createPool('shoot.wav', maxPlayers: 8);
      _pools['hit.wav'] = await FlameAudio.createPool('hit.wav', maxPlayers: 6);
      _pools['explode.wav'] = await FlameAudio.createPool('explode.wav', maxPlayers: 4);
      _pools['reward.wav'] = await FlameAudio.createPool('reward.wav', maxPlayers: 2);
      _pools['upgrade.wav'] = await FlameAudio.createPool('upgrade.wav', maxPlayers: 2);
      _pools['boss.wav'] = await FlameAudio.createPool('boss.wav', maxPlayers: 2);
      _poolsReady = true;
    } catch (e) {
      print("AudioPool init error (will use fallback): $e");
      _poolsReady = false;
    }
  }

  static void playBGM(String filename) {
    if (!bgmEnabled || !_initialized) return;
    try {
      FlameAudio.bgm.play(filename, volume: 0.5);
    } catch (e) {
      print("Failed to play BGM: $e");
    }
  }

  static void stopBGM() {
    if (!_initialized) return;
    FlameAudio.bgm.stop();
  }

  static void playSFX(String filename, {double volume = 0.8, int throttleMs = 120}) {
    if (!sfxEnabled || !_initialized) return;

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int? last = _lastPlayedMap[filename];
    if (last != null && now - last < throttleMs) return;
    _lastPlayedMap[filename] = now;

    try {
      if (_poolsReady && _pools.containsKey(filename)) {
        _pools[filename]!.start(volume: volume);
      } else {
        FlameAudio.play(filename, volume: volume);
      }
    } catch (e) {
      print("SFX error ($filename): $e");
    }
  }
}
