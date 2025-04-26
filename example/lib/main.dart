import 'package:audio_box/audio_box.dart';
import 'package:flutter/material.dart';

final sourceMap = {
  'bgm_1': AssetAudioSource('assets/bgm/bgm_1_fixed.mp3'),
  'bgm_2': AssetAudioSource('assets/bgm/bgm_2.mp3'),
  'bgs': AssetAudioSource('assets/bgs/storm.wav'),
  'se_click': AssetAudioSource('assets/se/se.mp3'),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AudioBox audioBox = AudioBox();

  // Registering audio sources (from assets)
  // オーディオソースを（アセットから）登録する
  await audioBox.registerAll(sourceMap);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'audio_box Example', home: AudioDemoScreen());
  }
}

class AudioDemoScreen extends StatelessWidget {
  const AudioDemoScreen({super.key});

  static AudioBox _audioBox = AudioBox();

  Widget buildButton(
    String label,
    bool canUseJustAudio,
    bool canUseAudioplayers,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        //child: Align(alignment: Alignment.centerLeft, child: Text(label)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text("")],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('audio_box Example')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // If the same `channelKey` is used, calling the `play` method will switch to the new audio.
          // 同じ`channelKey`が使用されている場合、`play`メソッドを実行すると新しい音声に切り替わります。
          buildButton("✅ Play BGM1 (BGM1再生)", true, true, () async {
            await _audioBox.play(
              audioKey: 'bgm_1',
              channelKey: 'bgm',
              loop: true,
            );
          }),
          buildButton("✅ Play BGM2 (BGM2再生)", true, true, () async {
            await _audioBox.play(
              audioKey: 'bgm_2',
              channelKey: 'bgm',
              loop: true,
            );
          }),
          buildButton("✅ Play BGS (BGS再生)", true, true, () async {
            await _audioBox.play(
              audioKey: 'bgs',
              channelKey: 'bgs',
              loop: true,
            );
          }),

          // If no `channelKey` is specified, the same audio can be played repeatedly without interruption.
          // `channelKey`を指定しなければ、同じ音声を連続で再生することができます。
          buildButton("✅ Play SE1 (SE再生)", true, true, () async {
            await _audioBox.play(audioKey: 'se_click');
          }),

          // Stops the audio associated with the specified `channelKey`.
          // 指定した`channelKey`に関連付けられた音声を停止します。
          buildButton("✅ Stop BGM (BGM停止)", true, true, () async {
            await _audioBox.stop(channelKey: 'bgm');
          }),

          // If no `channelKey` is specified, all audio will be stopped.
          // `channelKey`を指定しない場合、すべての音声が停止します。
          buildButton("✅ Stop all audios (全ての音声停止)", true, true, () async {
            await _audioBox.stop();
          }),

          buildButton(
            "✅ Play BGM1 with fade-in (BGM1フェードイン)",
            true,
            true,
            () async {
              await _audioBox.play(
                audioKey: 'bgm_1',
                channelKey: 'bgm',
                loop: true,
                fadeDuration: const Duration(seconds: 1),
              );
            },
          ),

          // Fades out the audio associated with the specified `channelKey`.
          // 指定した`channelKey`に関連付けられた音声をフェードアウトします。
          buildButton(
            "❌ Stop BGM with fade-out (BGMフェードアウト)",
            true,
            true,
            () async {
              await _audioBox.stop(
                channelKey: 'bgm',
                fadeDuration: const Duration(seconds: 1),
              );
            },
          ),
          buildButton(
            "❌ Resume BGM with fade-in (BGM再開フェードイン)",
            true,
            true,
            () async {
              await _audioBox.resume(
                channelKey: 'bgm',
                fadeDuration: const Duration(seconds: 1),
              );
            },
          ),
          buildButton(
            "❌ Pause BGM with fade-out (BGM一時停止フェードアウト)",
            true,
            true,
            () async {
              await _audioBox.pause(
                channelKey: 'bgm',
                fadeDuration: const Duration(seconds: 1),
              );
            },
          ),
        ],
      ),
    );
  }
}
