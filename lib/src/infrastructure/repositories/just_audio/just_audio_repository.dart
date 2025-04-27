// lib/src/data/repositories/just_audio_repository.dart
import 'dart:async';
import 'dart:math';

import 'package:just_audio/just_audio.dart';

import '../../../domain/models/audio_source_entry.dart';
import '../../../domain/models/audio_status.dart';
import '../../../domain/models/player_settings.dart';
import '../../../domain/repositories/audio_repository.dart';

class JustAudioRepository implements AudioRepository {
  final _sourceMap = <String, AudioSourceEntry>{};

  // キーごとの複数プレイヤー（channel==nullの場合の管理）
  final _players = <String, List<AudioPlayer>>{};
  // channel指定の場合の管理：各チャンネルにつき1つのAudioPlayerを保持
  final _playersByChannel = <String, AudioPlayer>{};

  final _status = <String, AudioStatus>{};
  final _autoDisposeTimers = <String, Timer>{};

  double _masterVolume = 1.0;
  double _masterSpeed = 1.0;
  double _masterPitch = 1.0;

  // 各プレイヤーのユーザー設定音量（0.0〜1.0）
  final _playerSettings = <AudioPlayer, PlayerSettings>{};

  JustAudioRepository({
    double masterVolume = 1.0,
    double masterSpeed = 1.0,
    double masterPitch = 1.0,
  }) {
    _masterVolume = masterVolume.clamp(0.0, 1.0);
    _masterSpeed = masterSpeed.clamp(0.0, 1.0);
    _masterPitch = masterPitch.clamp(0.0, 1.0);
  }

  @override
  Future<void> registerAll(Map<String, AudioSourceEntry> sources) async {
    _sourceMap.addAll(sources);
  }

  @override
  Future<void> preload({
    required String key,
    Duration? autoDisposeAfter,
  }) async {
    if (!_sourceMap.containsKey(key)) {
      throw ArgumentError('No path registered for key: $key');
    }
    final player = AudioPlayer();
    await _setSourceToPlayer(player, _sourceMap[key]!);
    final playerSetting = _playerSettings[player];
    playerSetting?.volume = 1.0;
    playerSetting?.speed = 1.0;
    playerSetting?.pitch = 1.0;
    await player.setVolume(1.0 * _masterVolume);
    await player.setSpeed(1.0 * _masterSpeed);
    // TODO just_audio は pitch 調整未対応
    // await player.setPitch(1.0 * _masterPitch);
    _players.putIfAbsent(key, () => []).add(player);
    _status[key] = AudioStatus.preloaded;
    if (autoDisposeAfter != null) {
      _autoDisposeTimers[key]?.cancel();
      _autoDisposeTimers[key] = Timer(autoDisposeAfter, () {
        dispose(key: key);
      });
    }
  }

  @override
  Future<void> preloadAll({
    required List<String> keys,
    Duration? autoDisposeAfter,
  }) async {
    for (final key in keys) {
      await preload(key: key, autoDisposeAfter: autoDisposeAfter);
    }
  }

  @override
  Future<void> dispose({required String key}) async {
    // channel指定のプレイヤーは _playersByChannel で管理しているので対象外
    if (_players.containsKey(key)) {
      for (final player in _players[key]!) {
        await player.dispose();
        _playerSettings.remove(player);
      }
      _players.remove(key);
    }
    _status[key] = AudioStatus.disposed;
    _autoDisposeTimers[key]?.cancel();
    _autoDisposeTimers.remove(key);
  }

  @override
  Future<void> disposeAll({required List<String> keys}) async {
    for (final key in keys) {
      await dispose(key: key);
    }
  }

  @override
  Future<bool> isPreloaded({required String channel}) async {
    return _status[channel] == AudioStatus.preloaded;
  }

  @override
  Future<AudioStatus> getStatus({required String channel}) async {
    return _status[channel] ?? AudioStatus.notInitialized;
  }

  @override
  Future<Duration> getPosition({required String channel}) async {
    // channel指定の場合は対象外。ここはキーごとのListから先頭のものを返す
    if (!_players.containsKey(channel) || _players[channel]!.isEmpty) {
      return Duration.zero;
    }
    return _players[channel]!.first.position;
  }

  @override
  double getMasterVolume() => _masterVolume;

  @override
  Future<void> setMasterVolume(double volume) async {
    _masterVolume = _adjustVolume(volume.clamp(0.0, 1.0));
    for (final entry in _playerSettings.entries) {
      final player = entry.key;
      final PlayerSettings playerSettings = entry.value;
      await player.setVolume(playerSettings.volume * _masterVolume);
    }
  }

  @override
  double getMasterSpeed() => _masterSpeed;

  @override
  Future<void> setMasterSpeed(double speed) async {
    _masterSpeed = speed.clamp(0.5, 2.0);
    for (final entry in _playerSettings.entries) {
      final player = entry.key;
      final PlayerSettings playerSettings = entry.value;
      await player.setSpeed(playerSettings.speed * _masterSpeed);
    }
  }

  @override
  double getMasterPitch() => _masterPitch;

  @override
  Future<void> setMasterPitch(double pitch) async {
    // TODO just_audio がピッチ調整に対応し次第実装
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
    if (!_sourceMap.containsKey(audioKey)) {
      throw ArgumentError('No path registered for key: $audioKey');
    }
    if (playPosition != null && loop != true) {
      throw ArgumentError('loopStartPosition requires loop: true');
    }

    late AudioPlayer player;
    if (channelKey != null) {
      // channel指定の場合：1チャンネルにつき1つのプレイヤーを利用
      if (_playersByChannel.containsKey(channelKey)) {
        player = _playersByChannel[channelKey]!;
        await player.stop();
      } else {
        player = AudioPlayer();
        _playersByChannel[channelKey] = player;
        _playerSettings[player]?.volume = 1.0;
      }
    } else {
      // channel==null → 連続再生可能（新規プレイヤー作成）
      player = AudioPlayer();
      _playerSettings[player]?.volume = 1.0;
      _players.putIfAbsent(audioKey, () => []).add(player);
    }

    await _setSourceToPlayer(player, _sourceMap[audioKey]!);

    if (loop) {
      player.setLoopMode(LoopMode.one);
    } else {
      player.setLoopMode(LoopMode.off);
    }

    if (loopStart != null) {
      await player.seek(loopStart);
    }
    await player.setSpeed(speed);
    if (fadeDuration != null) {
      final PlayerSettings playerSettings =
          _playerSettings[player] ?? PlayerSettings();
      await _fadeVolume(
        player,
        from: 0.0,
        to: playerSettings.volume,
        duration: fadeDuration,
      );
    }
    await player.play();
    _status[audioKey] = AudioStatus.playing;

    if (loop && playPosition != null) {
      player.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          player.seek(playPosition);
          player.play();
        }
      });
    }
  }

  @override
  Future<void> stop({String? channelKey, Duration? fadeDuration}) async {
    // channelKey が null の場合は全ての音声を停止
    // if (channelKey == null) {
    //   for (final k in _players.keys.toList()) {
    //     await stop(audioKey: k, fadeDuration: fadeDuration);
    //   }
    //   for (final ch in _playersByChannel.keys.toList()) {
    //     await stop(channelKey: ch, fadeDuration: fadeDuration);
    //   }
    //   return;
    // }
    //
    // if (channelKey != null) {
    //   final player = _playersByChannel[channelKey];
    //   if (player == null) return;
    //   if (fadeDuration != null) {
    //     final currentUserVol = (player.volume / _masterVolume);
    //     await _fadeVolume(
    //       player,
    //       from: currentUserVol,
    //       to: 0.0,
    //       duration: fadeDuration,
    //     );
    //   }
    //   await player.stop();
    //   _playersByChannel.remove(channelKey);
    // } else if (audioKey != null) {
    //   if (!_players.containsKey(audioKey)) return;
    //   for (final player in _players[audioKey]!) {
    //     if (fadeDuration != null) {
    //       final currentUserVol = (player.volume / _masterVolume);
    //       await _fadeVolume(
    //         player,
    //         from: currentUserVol,
    //         to: 0.0,
    //         duration: fadeDuration,
    //       );
    //     }
    //     await player.stop();
    //   }
    //   _status[audioKey] = AudioStatus.stopped;
    //   _players.remove(audioKey);
    // }
  }

  @override
  Future<void> pause({
    String? key,
    String? channelKey,
    Duration? fadeDuration,
  }) async {
    // key と channel の同時指定はエラー
    if (key != null && channelKey != null) {
      throw ArgumentError('pause: keyとchannelは同時に指定できません');
    }
    if (channelKey != null) {
      final player = _playersByChannel[channelKey];
      if (player == null) return;
      if (fadeDuration != null) {
        final currentUserVol = (player.volume / _masterVolume);
        await _fadeVolume(
          player,
          from: currentUserVol,
          to: 0.0,
          duration: fadeDuration,
        );
      }
      await player.pause();
    } else {
      if (!_players.containsKey(key)) return;
      for (final player in _players[key]!) {
        if (fadeDuration != null) {
          final currentUserVol = (player.volume / _masterVolume);
          await _fadeVolume(
            player,
            from: currentUserVol,
            to: 0.0,
            duration: fadeDuration,
          );
        }
        await player.pause();
      }
    }
    _status[key!] = AudioStatus.paused;
  }

  @override
  Future<void> resume({
    String? key,
    String? channelKey,
    double? volume,
    double? speed,
    double? pitch,
    bool? loop,
    Duration? fadeDuration,
    Duration? playPosition,
  }) async {
    // key と channel の同時指定はエラー
    if (key != null && channelKey != null) {
      throw ArgumentError('resume: keyとchannelは同時に指定できません');
    }
    // 両方とも null の場合は全再生
    if (key == null && channelKey == null) {
      for (final k in _players.keys) {
        await resume(
          key: k,
          fadeDuration: fadeDuration,
          playPosition: playPosition,
          speed: speed,
        );
      }
      for (final ch in _playersByChannel.keys) {
        await resume(
          channelKey: ch,
          fadeDuration: fadeDuration,
          playPosition: playPosition,
          speed: speed,
        );
      }
      return;
    }

    if (channelKey != null) {
      final player = _playersByChannel[channelKey];
      if (player == null) return;
      if (playPosition != null) {
        await player.seek(playPosition);
      }
      if (speed != null) {
        await player.setSpeed(speed);
      }
      if (fadeDuration != null) {
        final PlayerSettings playerSettings = _playerSettings[player]!;
        await _fadeVolume(
          player,
          from: 0.0,
          to: playerSettings.volume,
          duration: fadeDuration,
        );
      }
      await player.play();
    } else if (key != null) {
      if (!_players.containsKey(key)) return;
      for (final player in _players[key]!) {
        if (playPosition != null) {
          await player.seek(playPosition);
        }
        if (speed != null) {
          await player.setSpeed(speed);
        }
        if (fadeDuration != null) {
          final PlayerSettings playerSettings = _playerSettings[player]!;
          await _fadeVolume(
            player,
            from: 0.0,
            to: playerSettings.volume,
            duration: fadeDuration,
          );
        }
        await player.play();
      }
    }
    if (key != null) {
      _status[key] = AudioStatus.playing;
    }
  }

  @override
  Future<void> changeVolume({
    String? key,
    String? channel,
    required double volume,
    Duration? fadeDuration,
  }) async {
    if (key != null && channel != null) {
      throw ArgumentError('setVolume: keyとchannelは同時に指定できません');
    }
    final perceptualVolume = _adjustVolume(volume);
    if (channel != null) {
      final player = _playersByChannel[channel];
      if (player == null) return;
      _playerSettings[player]?.volume = perceptualVolume;
      if (fadeDuration != null) {
        final currentUserVol = (player.volume / _masterVolume);
        await _fadeVolume(
          player,
          from: currentUserVol,
          to: perceptualVolume,
          duration: fadeDuration,
        );
      } else {
        await player.setVolume(perceptualVolume * _masterVolume);
      }
    } else {
      if (!_players.containsKey(key)) return;
      for (final player in _players[key]!) {
        _playerSettings[player]?.volume = perceptualVolume;
        if (fadeDuration != null) {
          final currentUserVol = (player.volume / _masterVolume);
          await _fadeVolume(
            player,
            from: currentUserVol,
            to: perceptualVolume,
            duration: fadeDuration,
          );
        } else {
          await player.setVolume(perceptualVolume * _masterVolume);
        }
      }
    }
  }

  @override
  Future<void> changeSpeed({
    String? key,
    String? channel,
    required double speed,
    Duration? fadeDuration,
  }) async {
    if (key != null && channel != null) {
      throw ArgumentError('changeSpeed: keyとchannelは同時に指定できません');
    }
    if (channel != null) {
      final player = _playersByChannel[channel];
      if (player == null) return;
      if (fadeDuration != null) {
        await _fadeSpeed(
          player,
          from: player.speed,
          to: speed,
          duration: fadeDuration,
        );
      } else {
        await player.setSpeed(speed);
      }
    } else {
      if (!_players.containsKey(key)) return;
      for (final player in _players[key]!) {
        if (fadeDuration != null) {
          await _fadeSpeed(
            player,
            from: player.speed,
            to: speed,
            duration: fadeDuration,
          );
        } else {
          await player.setSpeed(speed);
        }
      }
    }
  }

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

  // ----- Private Helpers -----
  Future<void> _fadeVolume(
    AudioPlayer player, {
    required double from,
    required double to,
    required Duration duration,
  }) async {
    const steps = 20;
    final stepTime = duration.inMilliseconds ~/ steps;
    final stepSize = (to - from) / steps;
    for (int i = 0; i <= steps; i++) {
      final userVolume = from + (stepSize * i);
      final actualVolume = userVolume * _masterVolume;
      await player.setVolume(actualVolume.clamp(0.0, 1.0));
      await Future.delayed(Duration(milliseconds: stepTime));
    }
  }

  Future<void> _fadeSpeed(
    AudioPlayer player, {
    required double from,
    required double to,
    required Duration duration,
  }) async {
    const steps = 20;
    final stepTime = duration.inMilliseconds ~/ steps;
    final stepSize = (to - from) / steps;
    for (int i = 0; i <= steps; i++) {
      final speed = from + (stepSize * i);
      await player.setSpeed(speed.clamp(0.5, 2.0));
      await Future.delayed(Duration(milliseconds: stepTime));
    }
  }

  double _adjustVolume(double linearVolume) {
    // perceptualVolume = pow(linearVolume, 2)
    return pow(linearVolume, 2).toDouble();
  }

  Future<void> _setSourceToPlayer(
    AudioPlayer player,
    AudioSourceEntry source,
  ) async {
    if (source is AssetAudioSource) {
      await player.setAsset(source.assetPath);
    } else if (source is FileAudioSource) {
      await player.setFilePath(source.filePath);
    } else if (source is UrlAudioSource) {
      await player.setUrl(source.url);
    } else {
      throw UnsupportedError(
        'Unsupported AudioSourceEntry type: ${source.runtimeType}',
      );
    }
  }
}
