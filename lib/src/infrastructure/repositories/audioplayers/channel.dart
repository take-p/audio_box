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

    // 人間の耳に合わせて補正
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
    double volume = 1.0,
    double speed = 1.0,
    double pitch = 1.0,
    bool loop = false,
    Duration? fadeDuration,
    Duration? loopStart,
    Duration? loopEnd,
    Duration? playPosition,
  }) async {
    // プリロードしていなければ音声読み込み
    if (!_isPreload) {
      // 指定キーの音声をロード
      Source source = _getSource(audioKey);
      await _player.setSource(source);
    }

    // ループ設定
    await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);

    // 再生位置を初期に設定 TODO playとresumeの違いはここだけなので統合できないか？
    await _player.seek(Duration.zero); // Timeout

    // フェード再生するか否か
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
      await _fade(_player, 0.0, volume, fadeDuration);
      // フェードフラグOFF
      _isFade = false;
    } else {
      // 音量設定
      await _setPerceivedVolume(volume);
      // 再生
      await _player.resume();
    }
    return;
  }

  Future<void> resume({
    double? volume,
    bool? loop,
    Duration? fadeDuration,
  }) async {
    // ループ設定（指定がなければ変更せず）
    if (loop != null) {
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    }

    // フェード再生するか否か
    if (fadeDuration != null) {
      // 音量0で再生。TODO 将来的に0以外からフェードさせたいケースがあるかも
      await _setPerceivedVolume(0.0);
      await _player.resume();
      // フェード処理
      await _fade(_player, 0.0, _volume, fadeDuration);
    } else {
      // 音量設定
      _setPerceivedVolume(_volume);
      // 再開
      await _player.resume();
    }
  }

  Future<void> pause({Duration? fadeDuration}) async {
    // フェード処理
    if (fadeDuration != null) {
      // フェード処理
      _isFade = true;
      final perceivedVolume = _adjustVolume(_volume);
      await _fade(_player, perceivedVolume, 0.0, fadeDuration);
      _isFade = false;
    }
    // 停止
    await _player.pause();
  }

  Future<void> stop({Duration? fadeDuration}) async {
    // フェード処理
    if (fadeDuration != null) {
      // フェード処理
      _isFade = true;
      final perceivedVolume = _adjustVolume(_volume);
      await _fade(_player, perceivedVolume, 0.0, fadeDuration);
      _isFade = false;
    }
    // 停止
    await _player.stop();
  }

  // 人間の耳に合わせて補正
  double _adjustVolume(double volume) {
    return pow(volume, 2).toDouble();
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

  Future<void> _fade(
    AudioPlayer player,
    double from,
    double to,
    Duration duration,
  ) async {
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
      // 人間の感覚に調整
      final perceivedVolume = _adjustVolume(userVolume);
      // 音量設定
      await player.setVolume(perceivedVolume);
      // 待機
      await Future.delayed(Duration(milliseconds: stepTime));
    }
  }

  Future<void> _setPerceivedVolume(double volume) async {
    // 人間の耳に合わせて補正
    final perceivedVolume = _adjustVolume(volume);
    await _player.setVolume(perceivedVolume);
  }
}
