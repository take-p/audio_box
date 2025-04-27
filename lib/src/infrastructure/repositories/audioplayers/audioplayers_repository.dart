import 'package:audio_box/src/domain/models/audio_source_entry.dart';
import 'package:audio_box/src/domain/models/audio_status.dart';
import 'package:audio_box/src/domain/repositories/audio_repository.dart';
import 'package:audio_box/src/infrastructure/repositories/audioplayers/channel.dart';
import 'package:uuid/uuid.dart';

class AudioPlayersRepository implements AudioRepository {
  // ソース
  final Map<String, AudioSourceEntry> _sources = {};
  // プレーヤー
  // final Map<String, AudioPlayer> _players = {};
  final Map<String, Channel> _channels = {};

  /// volumeは3種類ある。
  /// - volume: プレーヤーごとのボリューム
  /// - masterVolume: 全体の出力レベル
  /// - effectiveVolume: プレーヤーのボリュームに全体の出力レベルを掛けたもの
  /// - perceivedVolume: 人間の耳に合わせて補正した値
  static double masterVolume = 0.5;
  static double masterSpeed = 1.0;
  static double masterPitch = 1.0;

  @override
  double getMasterVolume() => masterVolume;
  @override
  Future<void> setMasterVolume(double volume) async {
    masterVolume = volume;

    // 全てのチャンネルのボリュームを変更
    for (Channel channel in _channels.values) {
      channel.updateVolume();
    }
  }

  @override
  double getMasterSpeed() => masterSpeed;
  @override
  Future<void> setMasterSpeed(double speed) async {
    masterSpeed = speed;
  }

  @override
  double getMasterPitch() => masterPitch;
  @override
  Future<void> setMasterPitch(double pitch) async {
    masterPitch = pitch;
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
    Duration? loopStart,
    Duration? loopEnd,
    Duration? fadeDuration,
    Duration? playPosition,
  }) async {
    // チャンネル取得
    Channel channel = _getChannel(channelKey);

    // マスターボリューム反映
    final effectiveVolume = volume * masterVolume;

    channel.play(
      audioKey: audioKey,
      volume: effectiveVolume,
      loop: loop,
      fadeDuration: fadeDuration,
    );
  }

  @override
  Future<void> resume({
    required String channelKey,
    double volume = 1.0,
    double speed = 1.0,
    double pitch = 1.0,
    bool? loop,
    Duration? fadeDuration,
    Duration? playPosition,
  }) async {
    // チャンネル取得
    Channel channel = _getChannel(channelKey);

    // マスターボリューム反映
    final effectiveVolume = volume * masterVolume;

    channel.resume(volume: effectiveVolume, fadeDuration: fadeDuration);
  }

  @override
  Future<void> stop({String? channelKey, Duration? fadeDuration}) async {
    // チャンネル指定がない場合は全て停止
    if (channelKey == null) {
      for (Channel channel in _channels.values) {
        channel.stop(fadeDuration: fadeDuration);
      }
      return;
    } else {
      // チャンネル取得
      Channel channel = _getChannel(channelKey);

      channel.stop(fadeDuration: fadeDuration);
    }
  }

  @override
  Future<void> pause({
    required String channelKey,
    Duration? fadeDuration,
  }) async {
    // チャンネル取得
    Channel channel = _getChannel(channelKey);

    channel.pause(fadeDuration: fadeDuration);
  }

  @override
  Future<void> changeVolume({
    required String channel,
    required double volume,
    Duration? fadeDuration,
  }) async {
    // プレイヤー取得
    // AudioPlayer player = _getPlayer(channel);

    // player.setVolume(volume);

    _channels[channel]?.setVolume(volume * masterVolume);
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

  Channel _getChannel(String? channelKey) {
    // チャンネル指定なし
    if (channelKey == null) {
      // チャンネル作成
      final channel = Channel(sources: _sources);
      final uuid = Uuid();
      _channels[uuid.v4()] = channel;
      return channel;
    }
    // チャンネル指定あり
    else {
      // 既にチャンネルが存在する
      if (_channels.containsKey(channelKey)) {
        return _channels[channelKey]!;
      } else {
        final channel = Channel(sources: _sources);
        _channels[channelKey] = channel;
        return channel;
      }
    }
  }
}
