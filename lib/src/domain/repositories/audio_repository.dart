import '../../../audio_box.dart';

abstract interface class AudioRepository {
  /// キーとファイルパスのペアを登録
  Future<void> registerAll(Map<String, AudioSourceEntry> sources);

  /// メモリ読込（プリロード）
  Future<void> preload({required String key, Duration? autoDisposeAfter});
  Future<void> preloadAll({
    required List<String> keys,
    Duration? autoDisposeAfter,
  });

  /// メモリ解放
  Future<void> dispose({required String key});
  Future<void> disposeAll({required List<String> keys});

  /// マスターボリューム
  double getMasterVolume();
  Future<void> setMasterVolume(double volume);

  /// マスタースピード
  double getMasterSpeed();
  Future<void> setMasterSpeed(double speed);

  /// マスターピッチ
  double getMasterPitch();
  Future<void> setMasterPitch(double pitch);

  /// 音声操作
  ///
  /// - [audioKey] は必須です。
  /// - [channelKey] を指定した場合、そのチャンネルに対して処理を行います。
  ///   （playメソッドでは、keyとchannelを同時指定可能です）
  /// - [stop]、[pause]、[resume]、[changeVolume]、[changeSpeed] では、keyとchannelが同時指定された場合はエラーをスローし、
  ///   両方とも null の場合は全ての音声に対して処理を行います。
  Future<void> play({
    required String audioKey,
    String? channelKey,
    double volume,
    double speed,
    double pitch,
    bool loop = false,
    Duration? fadeDuration,
    Duration? loopStart,
    Duration? loopEnd,

    Duration? playPosition,
  });

  Future<void> stop({String? channelKey, Duration? fadeDuration});

  Future<void> pause({required String channelKey, Duration? fadeDuration});

  Future<void> resume({
    required String channelKey,
    bool? loop,
    double volume = 1.0,
    double speed = 1.0,
    double pitch = 1.0,
    Duration? fadeDuration,
    Duration? playPosition,
  });

  /// 音声調整
  Future<void> changeVolume({
    required String channel,
    required double volume,
    Duration? fadeDuration,
  });

  Future<void> changeSpeed({
    required String channel,
    required double speed,
    Duration? fadeDuration,
  });

  Future<void> changePitch({
    required String channel,
    required double pitch,
    Duration? fadeDuration,
  });

  /// 状態取得
  Future<bool> isPreloaded({required String channel});
  Future<AudioStatus> getStatus({required String channel});
  Future<Duration> getPosition({required String channel});
}
