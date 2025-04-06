import 'dart:math';

import 'package:audio_box/src/domain/models/audio_source_entry.dart';
import 'package:audio_box/src/domain/models/audio_status.dart';
import 'package:audio_box/src/domain/repositories/audio_repository.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';

class AudioPlayersRepository implements AudioRepository {
  // ソース
  final Map<String, AudioSourceEntry> _sources = {};
  // プレーヤー
  final Map<String, AudioPlayer> _players = {};

  /// volumeは3種類ある。
  /// - volume: プレーヤーごとのボリューム
  /// - masterVolume: 全体の出力レベル
  /// - actualVolume: プレーヤーのボリュームに全体の出力レベルを掛けたもの
  /// - adjustedVolume: 人間の耳に合わせて補正した値
  double _masterVolume = 1.0;
  double _masterSpeed = 1.0;
  double _masterPitch = 1.0;

  @override
  double getMasterVolume() => _masterVolume;
  @override
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = volume;
    // 全てのチャンネルのボリュームを変更
    for (AudioPlayer player in _players.values) {
      final actualVolume = player.volume * _masterVolume;
      final adjustedVolume = _adjustVolume(actualVolume);
      player.setVolume(adjustedVolume);
    }
  }

  @override
  double getMasterSpeed() => _masterSpeed;
  @override
  Future<void> setMasterSpeed(double speed) async {
    _masterSpeed = speed;
  }

  @override
  double getMasterPitch() => _masterPitch;
  @override
  Future<void> setMasterPitch(double pitch) async {
    _masterPitch = pitch;
  }

  // リソース登録
  @override
  Future<void> registerAll(Map<String, AudioSourceEntry> sources) async {
    _sources.addAll(sources);
  }

  // プリロード
  @override
  Future<void> preload({required String key, Duration? autoDisposeAfter}) {
    // TODO: implement preload
    throw UnimplementedError();
  }

  @override
  Future<void> preloadAll({
    required List<String> keys,
    Duration? autoDisposeAfter,
  }) {
    // TODO: implement preloadAll
    throw UnimplementedError();
  }

  @override
  Future<bool> isPreloaded({required String channel}) {
    // TODO: implement isPreloaded
    throw UnimplementedError();
  }

  // 解放
  @override
  Future<void> dispose({required String key}) {
    // TODO: implement dispose
    throw UnimplementedError();
  }

  @override
  Future<void> disposeAll({required List<String> keys}) {
    // TODO: implement disposeAll
    throw UnimplementedError();
  }

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
  }) async {
    // プレイヤー取得
    AudioPlayer player = _getPlayer(channelKey);
    // ソース取得・設定（プリロード済みの場合はスキップ）
    Source source = _getSource(audioKey);
    await player.setSource(source);

    // ループ設定
    await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);

    // 音量はマスターボリュームを反映させる
    double actualVolume = volume * _masterVolume;
    // 再生速度設定
    // TODO Audioplayersは未対応？
    // ピッチ変更
    // TODO Audioplayersは未対応？

    // 再生位置を初期に設定 TODO playとresumeの違いはここだけなので統合できないか？
    await player.seek(Duration.zero);

    // フェード再生するか否か
    if (fadeDuration != null) {
      // 音量0で再生。TODO 将来的に0以外からフェードさせたいケースがあるかも
      final double adjustedVolume = _adjustVolume(volume * _masterVolume);
      await player.setVolume(0.0 * _masterVolume);
      await player.resume();
      // フェード処理
      await _fade(player, 0.0, adjustedVolume, fadeDuration);
    } else {
      // 音量設定
      final double adjustedVolume = _adjustVolume(actualVolume);
      await player.setVolume(adjustedVolume);
      // 再生
      await player.resume();
    }
  }

  @override
  Future<void> resume({
    required String channel,
    double volume = 1.0,
    double speed = 1.0,
    double pitch = 1.0,
    bool? loop,
    Duration? fadeDuration,
    Duration? playPosition,
  }) async {
    // プレイヤー取得
    AudioPlayer player = _getPlayer(channel);

    // ループ設定（指定がなければ変更せず）
    if (loop != null) {
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
    }

    // 音量はマスターボリュームを反映させる
    double actualVolume = 1.0 * _masterVolume;
    // 再生速度設定
    // TODO Audioplayersは未対応？
    // ピッチ変更
    // TODO Audioplayersは未対応？

    // フェード再生するか否か
    if (fadeDuration != null) {
      // 音量0で再生。TODO 将来的に0以外からフェードさせたいケースがあるかも
      final double adjustedVolume = _adjustVolume(0.0 * _masterVolume);
      await player.setVolume(adjustedVolume);
      await player.resume();
      // フェード処理
      await _fade(player, 0.0, adjustedVolume, fadeDuration);
    } else {
      // 音量設定
      final double adjustedVolume = _adjustVolume(actualVolume);
      await player.setVolume(adjustedVolume);
      // 再開
      await player.resume();
    }
  }

  @override
  Future<void> stop({required String channel, Duration? fadeDuration}) async {
    // プレイヤー取得
    AudioPlayer player = _getPlayer(channel);
    // フェード処理
    if (fadeDuration != null) {
      // フェード処理
      await _fade(player, player.volume, 0.0, fadeDuration);
    }
    // 停止
    await player.stop();
  }

  @override
  Future<void> pause({required String channel, Duration? fadeDuration}) async {
    // プレイヤー取得
    AudioPlayer player = _getPlayer(channel);
    // フェード処理
    if (fadeDuration != null) {
      // フェード処理
      await _fade(player, player.volume, 0.0, fadeDuration);
    }
    // 停止
    await player.pause();
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
      // 現在の音量
      final userVolume = from + (stepVolume * i);
      // マスターボリュームを掛け合わせる
      final actualVolume = userVolume;
      // 音量設定
      await player.setVolume(actualVolume.clamp(0.0, 1.0));
      // 待機
      await Future.delayed(Duration(milliseconds: stepTime));
    }
  }

  AudioPlayer _getPlayer(String? channel) {
    // チャンネル指定なし
    if (channel == null) {
      // プレーヤー作成
      final uuid = Uuid();
      final player = _createPlayer(uuid.v4());
      // 終了後は自動解放
      player.onPlayerComplete.listen((event) async {
        await player.dispose();
      });
      return player;
    }
    // チャンネル指定あり
    else {
      // 既にチャンネルが存在する
      if (_players.containsKey(channel)) {
        return _players[channel]!;
      } else {
        return _createPlayer(channel);
      }
    }
  }

  AudioPlayer _createPlayer(String channel) {
    // プレーヤー作成
    AudioPlayer audioPlayer = AudioPlayer();
    // プレーヤーを_playersに追加
    _players[channel] = audioPlayer;
    // プレーヤー返却
    return audioPlayer;
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

  @override
  Future<void> changeVolume({
    required String channel,
    required double volume,
    Duration? fadeDuration,
  }) async {
    // プレイヤー取得
    AudioPlayer player = _getPlayer(channel);

    player.setVolume(volume);
  }

  @override
  Future<void> changeSpeed({
    required String channel,
    required double speed,
    Duration? fadeDuration,
  }) async {
    // TODO: implement changeSpeed
    throw UnimplementedError();
  }

  @override
  Future<void> changePitch({
    required String channel,
    required double pitch,
    Duration? fadeDuration,
  }) async {
    // TODO: implement changePitch
    throw UnimplementedError();
  }

  @override
  Future<Duration> getPosition({required String channel}) {
    // TODO: implement getPosition
    throw UnimplementedError();
  }

  @override
  Future<AudioStatus> getStatus({required String channel}) {
    // TODO: implement getStatus
    throw UnimplementedError();
  }

  double _adjustVolume(double volume) {
    return pow(volume, 2).toDouble();
  }
}
