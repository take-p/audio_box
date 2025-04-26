import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

import '../../../../audio_box.dart';

class Channel {
  // ソース
  Map<String, AudioSourceEntry> _sources = {};
  // プレーヤー
  final AudioPlayer _player = AudioPlayer();
  // 再生する音声のキー
  String? _audioKey;
  // フェード状況
  bool _isFade = false;
  // プリロード状況
  bool _isPreload = false;

  // 音量
  double _volume = 1.0;
  double _speed = 1.0;
  double _pitch = 1.0;

  Channel({required Map<String, AudioSourceEntry> sources}) {
    _sources = sources;
  }

  double getVolume() => _volume;
  Future<void> setVolume(double volume) async {
    _volume = volume;
    await _setPerceivedVolume(volume);
  }

  double getSpeed() => _speed;
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    throw UnimplementedError();
  }

  double getPitch() => _pitch;
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    throw UnimplementedError();
  }

  // プリロード
  Future<void> preload({
    required String audioKey,
    Duration? autoDisposeAfter,
  }) async {
    // プリロード済みの場合
    if (_isPreload) {
      return;
    }
    // 指定キーの音声をロード
    Source source = _getSource(audioKey);
    await _player.setSource(source);

    _audioKey = audioKey;
    _isPreload = true;
  }

  // 再生
  Future<void> play({
    required String audioKey,
    double? volume,
    double? speed,
    double? pitch,
    bool loop = false,
    Duration? fadeDuration,
    Duration? loopStart,
    Duration? loopEnd,
    Duration? playPosition,
  }) async {
    // プリロードしていなければ音声読み込み
    if (!_isPreload || audioKey != _audioKey) {
      // 指定キーの音声をロード
      Source source = _getSource(audioKey);
      await _player.setSource(source);
      _audioKey = audioKey;
      _isPreload = true;
    }

    // 再生位置を初期に設定
    await _player.seek(Duration.zero);

    await _fadeAndPlay(
      playAction: () => _player.resume(),
      fadeDuration: fadeDuration,
      volume: volume,
      loop: loop,
    );
  }

  Future<void> resume({
    double? volume,
    double? speed,
    double? pitch,
    bool? loop,
    Duration? fadeDuration,
  }) async {
    if (volume != null) {
      setVolume(volume);
    }

    await _fadeAndPlay(
      playAction: () => _player.resume(),
      fadeDuration: fadeDuration,
      volume: volume,
    );
  }

  Future<void> _fadeAndPlay({
    required Future<void> Function() playAction,
    Duration? fadeDuration,
    double? volume,
    bool? loop,
  }) async {
    // ループ設定（指定がなければ変更せず）
    if (loop != null) {
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    }

    if (fadeDuration != null) {
      // すでにフェード再生中の場合は処理をスキップ
      if (_isFade) {
        return;
      }

      // 音量0で再生。TODO 将来的に0以外からフェードさせたいケースがあるかも
      await _setPerceivedVolume(0.0);
      await _player.resume();

      // フェード処理
      _isFade = true;
      await _fade(0.0, _volume, fadeDuration);
      _isFade = false;
    }
    // 音量設定
    if (volume != null) {
      await setVolume(volume);
    }
    return playAction();
  }

  // 音声の停止処理
  Future<void> _fadeAndStop({
    required Future<void> Function() stopAction,
    Duration? fadeDuration,
  }) async {
    if (fadeDuration != null) {
      // すでにフェード再生中の場合は処理をスキップ
      if (_isFade) {
        return;
      }

      // フェード処理
      _isFade = true;
      await _fade(_volume, 0.0, fadeDuration);
      _isFade = false;
    }
    await stopAction();
  }

  Future<void> pause({Duration? fadeDuration}) async {
    await _fadeAndStop(
      stopAction: () => _player.pause(),
      fadeDuration: fadeDuration,
    );
  }

  Future<void> stop({Duration? fadeDuration}) async {
    await _fadeAndStop(
      stopAction: () => _player.stop(),
      fadeDuration: fadeDuration,
    );
  }

  Source _getSource(String key) {
    if (!_sources.containsKey(key)) {
      throw Exception("指定したキーのソースは存在しません。");
    }
    final source = _sources[key];

    if (source is AssetAudioSource) {
      String path = source.assetPath;
      // 先頭に"assets/"がついていたら削除
      if (path.startsWith('assets/')) {
        path = path.substring('assets/'.length);
      }
      return AssetSource(path);
    } else if (source is FileAudioSource) {
      return DeviceFileSource(source.filePath);
    } else if (source is UrlAudioSource) {
      return UrlSource(source.url);
    } else {
      throw UnsupportedError(
        'Unsupported AudioSourceEntry type: ${source.runtimeType}',
      );
    }
  }

  Future<void> _fade(double from, double to, Duration duration) async {
    // ボリュームを切り替える粒度。細かいほど自然
    const steps = 32;
    // フェード時間をステップ数で割り、1ステップあたりの時間を計算
    final stepTime = duration.inMilliseconds ~/ steps;
    // 1ステップごとに変動する音量の大きさ
    final stepVolume = (to - from) / steps;
    for (int i = 0; i <= steps; i++) {
      // フェードフラグがOFFになったら強制終了
      if (!_isFade) {
        break;
      }
      // 現在の音量
      final userVolume = from + (stepVolume * i);
      _setPerceivedVolume(userVolume);
      // 待機
      await Future.delayed(Duration(milliseconds: stepTime));
    }
  }

  Future<void> _setPerceivedVolume(double volume) async {
    // 人間の耳に合わせて補正
    final perceivedVolume = pow(volume, 2).toDouble();

    await _player.setVolume(perceivedVolume);
  }
}
