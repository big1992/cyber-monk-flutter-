import 'package:flame_audio/flame_audio.dart';

class AudioSystem {
  static bool _initialized = false;
  static bool bgmEnabled = true;
  static bool sfxEnabled = true;

  static final Map<String, int> _lastPlayedMap = {};
  
  // Manual WebAudio Pools to prevent channel exhaustion / garbage collection lockup
  static final Map<String, List<AudioPlayer>> _pools = {};
  static final Map<String, int> _poolIndexes = {};

  static Future<void> _createManualPool(String filename, int count) async {
    List<AudioPlayer> pool = [];
    for (int i = 0; i < count; i++) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setSource(AssetSource('audio/$filename'));
      pool.add(player);
    }
    _pools[filename] = pool;
    _poolIndexes[filename] = 0;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Load audio to cache to prevent stuttering lag when playing for the first time
    try {
      await FlameAudio.audioCache.loadAll([
        'bgm.mp3', 
        'shoot.wav', 
        'hit.wav', 
        'explode.wav', 
        'reward.wav', 
        'boss.wav', 
        'upgrade.wav'
      ]);

      // Prime the round-robin pools using standard AudioPlayers
      await _createManualPool('shoot.wav', 12);
      await _createManualPool('hit.wav', 8);
      await _createManualPool('explode.wav', 5);
      await _createManualPool('reward.wav', 3);
      await _createManualPool('upgrade.wav', 2);
      await _createManualPool('boss.wav', 2);
      
      FlameAudio.bgm.initialize();
      _initialized = true;
    } catch (e) {
      print("AudioSystem Error: Make sure audio files exist in assets/audio/ directory. ($e)");
    }
  }

  // Plays a background track (loops automatically)
  static void playBGM(String filename) {
    if (!bgmEnabled || !_initialized) return;
    try {
      FlameAudio.bgm.play(filename, volume: 0.5);
    } catch (e) {
      print("Failed to play BGM $filename: $e");
    }
  }

  static void stopBGM() {
    if (!_initialized) return;
    FlameAudio.bgm.stop();
  }

  // Plays a short sound effect
  static void playSFX(String filename, {double volume = 0.8, int throttleMs = 120}) {
    if (!sfxEnabled || !_initialized) return;

    final int now = DateTime.now().millisecondsSinceEpoch;
    if (_lastPlayedMap.containsKey(filename)) {
      if (now - _lastPlayedMap[filename]! < throttleMs) {
        return; // Throttled extremely conservatively for web stability
      }
    }
    _lastPlayedMap[filename] = now;

    try {
      if (_pools.containsKey(filename) && _pools[filename]!.isNotEmpty) {
        // Manual Round-Robin to bypass browser Garbage Collection limits
        int idx = _poolIndexes[filename]!;
        final p = _pools[filename]![idx];
        p.setVolume(volume);
        p.seek(Duration.zero);
        p.resume();
        _poolIndexes[filename] = (idx + 1) % _pools[filename]!.length;
      } else {
        FlameAudio.play(filename, volume: volume);
      }
    } catch (e) {
      print("Failed to play SFX $filename: $e");
    }
  }
}
