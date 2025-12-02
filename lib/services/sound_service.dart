import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const String _bgmAsset = 'sounds/background_music.mp3';
  static const List<String> _sfxAssets = [
    'sounds/sfx/Pop Up 1.mp3',
    'sounds/sfx/Pop Up 2.mp3',
    'sounds/sfx/Pop Up 3.mp3',
    'sounds/sfx/Pop Up 4.mp3',
  ];

  final AudioPlayer _bgmPlayer = AudioPlayer();
  AudioPlayer _sfxPlayer = AudioPlayer();
  final Random _rand = Random();

  double _bgmVolume = 0.2;
  double _sfxVolume = 0.8;
  bool _initialized = false;
  bool _isBgmPlaying = false;
  bool _contextsSet = false;
  bool _listenersBound = false;

  static final AudioContext _bgmContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.game,
      audioFocus: AndroidAudioFocus.gain,
    ),
  );

  static final AudioContext _sfxContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: false,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  Future<void> init({double? bgmVolume, double? sfxVolume}) async {
    if (_initialized) {
      if (bgmVolume != null) _bgmVolume = bgmVolume;
      if (sfxVolume != null) _sfxVolume = sfxVolume;
      await _applyBgmState();
      return;
    }
    _initialized = true;
    if (bgmVolume != null) _bgmVolume = bgmVolume;
    if (sfxVolume != null) _sfxVolume = sfxVolume;
    await _setupAudioContexts();
    _bindBgmListeners();
    await _prepareBgmPlayer();
    await _prepareSfxPlayer();
    await _applyBgmState();
  }

  Future<void> setBgmVolume(double value) async {
    _bgmVolume = value;
    if (value <= 0) {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
      return;
    }
    await _bgmPlayer.setVolume(value);
    await _playIfNeeded();
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value;
    try {
      await _sfxPlayer.setVolume(value);
    } catch (_) {}
  }

  Future<void> playClick() async {
    if (_sfxVolume <= 0 || _sfxAssets.isEmpty) return;
    await _setupAudioContexts();
    await _prepareSfxPlayer();
    try {
      final asset = _sfxAssets[_rand.nextInt(_sfxAssets.length)];
      debugPrint('[SFX] play request -> $asset vol=$_sfxVolume');
      await _sfxPlayer.stop();
      await _sfxPlayer.setVolume(_sfxVolume);
      await _sfxPlayer.play(AssetSource(asset));
      debugPrint('[SFX] play started');
    } catch (e) {
      debugPrint('[SFX] play failed: $e -> recreating player');
      // Recreate the SFX player if it gets into a bad state (observed on some devices).
      try {
        await _sfxPlayer.dispose();
      } catch (_) {}
      _sfxPlayer = AudioPlayer();
      _contextsSet = false; // force reapply contexts next play
    }
  }

  Future<void> _restartBgm() async {
    await _applyBgmState();
  }

  Future<void> _applyBgmState() async {
    if (_bgmVolume <= 0) {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
      return;
    }
    await _setupAudioContexts();
    await _playIfNeeded();
  }

  Future<void> _playIfNeeded() async {
    if (_isBgmPlaying && _bgmPlayer.state == PlayerState.playing) return;
    try {
      await _prepareBgmPlayer();
      await _bgmPlayer.play(AssetSource(_bgmAsset), volume: _bgmVolume);
      _isBgmPlaying = true;
    } catch (_) {
      _isBgmPlaying = false;
    }
  }

  Future<void> dispose() async {
    await _bgmPlayer.stop();
    await _sfxPlayer.stop();
    await _bgmPlayer.dispose();
    await _sfxPlayer.dispose();
  }

  Future<void> resumeBgmIfEnabled() async {
    if (_bgmVolume <= 0) return;
    await _setupAudioContexts();
    await _prepareBgmPlayer();
    await _playIfNeeded();
  }

  Future<void> ensurePlaying() async {
    await resumeBgmIfEnabled();
  }

  Future<void> _setupAudioContexts() async {
    if (_contextsSet) return;
    try {
      debugPrint('[AudioContext] applying contexts');
      await _bgmPlayer.setAudioContext(_bgmContext);
      await _sfxPlayer.setAudioContext(_sfxContext);
      _contextsSet = true;
    } catch (e) {
      debugPrint('[AudioContext] failed to apply contexts: $e');
      _contextsSet = false;
    }
  }

  Future<void> _prepareBgmPlayer() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await _bgmPlayer.setVolume(_bgmVolume);
  }

  Future<void> _prepareSfxPlayer() async {
    await _sfxPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    await _sfxPlayer.setReleaseMode(ReleaseMode.release);
    await _sfxPlayer.setVolume(_sfxVolume);
  }

  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer.pause();
    } catch (_) {}
    _isBgmPlaying = false;
  }

  void _bindBgmListeners() {
    if (_listenersBound) return;
    _listenersBound = true;
    _bgmPlayer.onPlayerStateChanged.listen((state) {
      if (_bgmVolume <= 0) return;
      if (state == PlayerState.stopped ||
          state == PlayerState.completed ||
          state == PlayerState.paused) {
        _isBgmPlaying = false;
        _playIfNeeded();
      } else if (state == PlayerState.playing) {
        _isBgmPlaying = true;
      }
    });
    _bgmPlayer.onPlayerComplete.listen((_) {
      _isBgmPlaying = false;
      _playIfNeeded();
    });
  }
}
