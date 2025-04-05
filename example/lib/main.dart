import 'package:audio_box/audio_box.dart';
import 'package:flutter/material.dart';

final sourceMap = {
  'bgm_1': AssetAudioSource('assets/bgm/bgm_1_fixed.mp3'),
  'bgm_2': AssetAudioSource('assets/bgm/bgm_2.mp3'),
  'se_click': AssetAudioSource('assets/se/se.mp3'),
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioKit = AudioKit();

  // オーディオソースの登録（Asset 使用）
  await audioKit.registerAll(sourceMap);

  runApp(MyApp(audioKit: audioKit));
}

class MyApp extends StatelessWidget {
  final AudioKit audioKit;

  const MyApp({super.key, required this.audioKit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'audio_box Example',
      home: AudioDemoScreen(audioKit: audioKit),
    );
  }
}

class AudioDemoScreen extends StatelessWidget {
  final AudioKit audioKit;

  const AudioDemoScreen({super.key, required this.audioKit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('audio_box Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await audioKit.play(key: 'se_click');
              },
              child: const Text('Play SE'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await audioKit.play(key: 'bgm_1', channel: 'bgm', loop: true);
              },
              child: const Text('Play BGM1'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await audioKit.play(
                  key: 'bgm_2',
                  channel: 'bgm',
                  loop: true,
                  // loopStartPosition: Duration(milliseconds: 666),
                  loopStartPosition: Duration(seconds: 3),
                );
              },
              child: const Text('Play BGM2'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await audioKit.stop(channel: 'bgm');
              },
              child: const Text('Stop BGM'),
            ),
          ],
        ),
      ),
    );
  }
}
