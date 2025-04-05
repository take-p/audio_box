import 'package:meta/meta.dart';

import '../../audio_box.dart';
import '../domain/repositories/audio_repository.dart';
import '../infrastructure/repositories/just_audio_repository.dart';

enum AudioPackageType { justAudio }

class AudioBox implements AudioRepository {
  static AudioBox? _instance;
  late final AudioRepository _repository;

  /// ファクトリコンストラクタ（シングルトン）
  factory AudioBox({
    AudioPackageType type = AudioPackageType.justAudio,
    double masterVolume = 1.0,
  }) {
    _instance ??= AudioBox._internal(type, masterVolume);
    return _instance!;
  }

  AudioBox._internal(AudioPackageType type, double masterVolume) {
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

  // ===== 登録・プリロード・解放 =====
  @override
  Future<void> registerAll(Map<String, AudioSourceEntry> sources) =>
      _repository.registerAll(sources);

  @override
  Future<void> preload({required String key, Duration? autoDisposeAfter}) =>
      _repository.preload(key: key, autoDisposeAfter: autoDisposeAfter);

  @override
  Future<void> preloadAll({
    required List<String> keys,
    Duration? autoDisposeAfter,
  }) => _repository.preloadAll(keys: keys, autoDisposeAfter: autoDisposeAfter);

  @override
  Future<void> dispose({required String key}) => _repository.dispose(key: key);

  @override
  Future<void> disposeAll({required List<String> keys}) =>
      _repository.disposeAll(keys: keys);

  // ===== 全体設定 =====
  @override
  double getMasterVolume() => _repository.getMasterVolume();

  @override
  Future<void> setMasterVolume(double volume) =>
      _repository.setMasterVolume(volume);

  @override
  double getMasterSpeed() => _repository.getMasterSpeed();

  @override
  Future<void> setMasterSpeed(double speed) =>
      _repository.setMasterSpeed(speed);

  @override
  double getMasterPitch() => _repository.getMasterPitch();

  @override
  Future<void> setMasterPitch(double pitch) =>
      _repository.setMasterPitch(pitch);

  // ===== 音声制御 =====
  @override
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

  @override
  Future<void> stop({String? key, String? channel, Duration? fadeDuration}) =>
      _repository.stop(key: key, channel: channel, fadeDuration: fadeDuration);

  @override
  Future<void> pause({String? key, String? channel, Duration? fadeDuration}) =>
      _repository.pause(key: key, channel: channel, fadeDuration: fadeDuration);

  @override
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

  @override
  Future<void> changeVolume({
    String? key,
    String? channel,
    required double volume,
    Duration? fadeDuration,
  }) => _repository.changeVolume(
    key: key,
    channel: channel,
    volume: volume,
    fadeDuration: fadeDuration,
  );

  @override
  Future<void> changeSpeed({
    String? key,
    String? channel,
    required double speed,
    Duration? fadeDuration,
  }) => _repository.changeSpeed(
    key: key,
    channel: channel,
    speed: speed,
    fadeDuration: fadeDuration,
  );

  @override
  Future<void> changePitch({
    String? key,
    String? channel,
    required double pitch,
    Duration? fadeDuration,
  }) {
    // TODO: implement changePitch
    throw UnimplementedError();
  }

  // ===== 状態取得 =====
  @override
  Future<bool> isPreloaded({required String key}) =>
      _repository.isPreloaded(key: key);
  @override
  Future<AudioStatus> getStatus({required String key}) =>
      _repository.getStatus(key: key);
  @override
  Future<Duration> getPosition({required String key}) =>
      _repository.getPosition(key: key);
}
