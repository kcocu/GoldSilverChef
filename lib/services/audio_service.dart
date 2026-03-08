import 'package:audioplayers/audioplayers.dart';

/// 게임 오디오 서비스
class AudioService {
  static final AudioService _instance = AudioService._();
  static AudioService get instance => _instance;

  AudioService._();

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  bool _bgmEnabled = true;
  bool _sfxEnabled = true;

  bool get bgmEnabled => _bgmEnabled;
  bool get sfxEnabled => _sfxEnabled;

  // ─── BGM ───

  Future<void> playBgm(String fileName, {double volume = 0.3}) async {
    if (!_bgmEnabled) return;
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(volume);
    await _bgmPlayer.play(AssetSource('sounds/$fileName'));
  }

  Future<void> playMenuBgm() => playBgm('bgm_casual.mp3');
  Future<void> playCookingBgm() => playBgm('bgm_cooking.mp3');

  Future<void> stopBgm() async {
    await _bgmPlayer.stop();
  }

  // ─── SFX ───

  Future<void> playSfx(String fileName, {double volume = 0.6}) async {
    if (!_sfxEnabled) return;
    await _sfxPlayer.setVolume(volume);
    await _sfxPlayer.play(AssetSource('sounds/$fileName'));
  }

  Future<void> playChop() => playSfx('chop.mp3');
  Future<void> playWater() => playSfx('water.mp3', volume: 0.4);
  Future<void> playFire() => playSfx('fire.mp3');
  Future<void> playBell() => playSfx('bell.mp3');
  Future<void> playCookware() => playSfx('cookware.mp3');

  // ─── 설정 ───

  void toggleBgm() {
    _bgmEnabled = !_bgmEnabled;
    if (!_bgmEnabled) _bgmPlayer.stop();
  }

  void toggleSfx() {
    _sfxEnabled = !_sfxEnabled;
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
  }
}
