import 'package:meta/meta.dart';

import '../../audio_box.dart';
import '../domain/repositories/audio_repository_i.dart';
import '../infrastructure/just_audio_repository.dart';

enum AudioPackageType { justAudio }

class AudioKit {
  static AudioKit? _instance;
  late final AudioRepository _repository;

  /// ファクトリコンストラクタ（シングルトン）
  factory AudioKit({
    AudioPackageType type = AudioPackageType.justAudio,
    double masterVolume = 1.0,
  }) {
    _instance ??= AudioKit._internal(type, masterVolume);
    return _instance!;
  }

  AudioKit._internal(AudioPackageType type, double masterVolume) {
    switch (type) {
      case AudioPackageType.justAudio:
        _repository = JustAudioRepository(masterVolume: masterVolume);
        break;
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _instance = null;
  }

  // ===== 登録・プリロード =====
  Future<void> registerAll(Map<String, AudioSourceEntry> sources) =>
      _repository.registerAll(sources);

  Future<void> preload({required String key, Duration? autoDisposeAfter}) =>
      _repository.preload(key: key, autoDisposeAfter: autoDisposeAfter);

  Future<void> preloadAll({
    required List<String> keys,
    Duration? autoDisposeAfter,
  }) => _repository.preloadAll(keys: keys, autoDisposeAfter: autoDisposeAfter);

  Future<void> dispose({required String key}) => _repository.dispose(key: key);
  Future<void> disposeAll({required List<String> keys}) =>
      _repository.disposeAll(keys: keys);

  // ===== 再生・制御 =====
  Future<void> play({
    required String key,
    String? channel,
    bool loop = false,
    Duration? fadeDuration,
    Duration? playPosition,
    double? playSpeed,
    Duration? loopStartPosition,
  }) => _repository.play(
    key: key,
    channel: channel,
    loop: loop,
    fadeDuration: fadeDuration,
    playPosition: playPosition,
    playSpeed: playSpeed,
    loopStartPosition: loopStartPosition,
  );

  Future<void> stop({String? key, String? channel, Duration? fadeDuration}) =>
      _repository.stop(key: key, channel: channel, fadeDuration: fadeDuration);

  Future<void> pause({
    required String key,
    String? channel,
    Duration? fadeDuration,
  }) =>
      _repository.pause(key: key, channel: channel, fadeDuration: fadeDuration);

  Future<void> resume({
    String? key,
    String? channel,
    Duration? fadeDuration,
    Duration? playPosition,
    double? playSpeed,
  }) => _repository.resume(
    key: key,
    channel: channel,
    fadeDuration: fadeDuration,
    playPosition: playPosition,
    playSpeed: playSpeed,
  );

  Future<void> setVolume({
    required String key,
    String? channel,
    required double volume,
    Duration? fadeDuration,
  }) => _repository.setVolume(
    key: key,
    channel: channel,
    volume: volume,
    fadeDuration: fadeDuration,
  );

  Future<void> changeSpeed({
    required String key,
    String? channel,
    required double playSpeed,
    Duration? fadeDuration,
  }) => _repository.changeSpeed(
    key: key,
    channel: channel,
    playSpeed: playSpeed,
    fadeDuration: fadeDuration,
  );

  // ===== 状態取得 =====
  Future<bool> isPreloaded({required String key}) =>
      _repository.isPreloaded(key: key);
  Future<AudioStatus> getStatus({required String key}) =>
      _repository.getStatus(key: key);
  Future<Duration> getPosition({required String key}) =>
      _repository.getPosition(key: key);

  // ===== マスターボリューム =====
  Future<void> setMasterVolume(double volume) =>
      _repository.setMasterVolume(volume);
  double getMasterVolume() => _repository.getMasterVolume();
}
