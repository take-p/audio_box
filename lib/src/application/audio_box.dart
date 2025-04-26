import 'package:audio_box/src/infrastructure/repositories/audioplayers/audioplayers_repository.dart';
import 'package:meta/meta.dart';

import '../../audio_box.dart';
import '../domain/repositories/audio_repository.dart';
import '../infrastructure/repositories/just_audio/just_audio_repository.dart';

enum AudioPackageType { justAudio, audioplayers }

class AudioBox implements AudioRepository {
  static AudioBox? _instance;
  late final AudioRepository _repository;

  /// ファクトリコンストラクタ（シングルトン）
  factory AudioBox({
    AudioPackageType type = AudioPackageType.audioplayers,
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
      case AudioPackageType.audioplayers:
        _repository = AudioPlayersRepository();
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
    required String audioKey,
    String? channelKey,
    double volume = 1.0,
    double speed = 1.0,
    double pitch = 1.0,
    bool loop = false,
    Duration? fadeDuration,
    Duration? loopStart,
    Duration? loopEnd,
    Duration? playPosition,
  }) => _repository.play(
    audioKey: audioKey,
    channelKey: channelKey,
    loop: loop,
    fadeDuration: fadeDuration,
    loopStart: loopStart,
    speed: speed,
    playPosition: playPosition,
  );

  @override
  Future<void> stop({String? channelKey, Duration? fadeDuration}) =>
      _repository.stop(channelKey: channelKey, fadeDuration: fadeDuration);

  @override
  Future<void> pause({required String channelKey, Duration? fadeDuration}) =>
      _repository.pause(channelKey: channelKey, fadeDuration: fadeDuration);

  @override
  Future<void> resume({
    required String channelKey,
    bool? loop,
    double volume = 1.0,
    double speed = 1.0,
    double pitch = 1.0,
    Duration? fadeDuration,
    Duration? playPosition,
  }) => _repository.resume(
    channelKey: channelKey,
    fadeDuration: fadeDuration,
    playPosition: playPosition,
  );

  @override
  Future<void> changeVolume({
    required String channel,
    required double volume,
    Duration? fadeDuration,
  }) => _repository.changeVolume(
    channel: channel,
    volume: volume,
    fadeDuration: fadeDuration,
  );

  @override
  Future<void> changeSpeed({
    required String channel,
    required double speed,
    Duration? fadeDuration,
  }) => _repository.changeSpeed(
    channel: channel,
    speed: speed,
    fadeDuration: fadeDuration,
  );

  @override
  Future<void> changePitch({
    required String channel,
    required double pitch,
    Duration? fadeDuration,
  }) {
    // TODO: implement changePitch
    throw UnimplementedError();
  }

  // ===== 状態取得 =====
  @override
  Future<bool> isPreloaded({required String channel}) =>
      _repository.isPreloaded(channel: channel);
  @override
  Future<AudioStatus> getStatus({required String channel}) =>
      _repository.getStatus(channel: channel);
  @override
  Future<Duration> getPosition({required String channel}) =>
      _repository.getPosition(channel: channel);
}
