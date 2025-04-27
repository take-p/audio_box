# audio_box

🎧 A simple and flexible audio manager for Flutter apps, designed to handle background music (BGM), sound effects (SE), and other audio playback with ease.

## Features

- ✅ Supports asset, file, and network audio sources
- 🔁 Loop playback with custom start positions
- 🔊 Volume, speed, and (planned) pitch control
- 📦 Simple API for BGM/SE switching via key or channel
- 🎚️ Global master volume/speed settings
- 🚀 Designed with clean architecture and extensibility in mind

## Getting started

Add `audio_box` to your `pubspec.yaml`:

```yaml
dependencies:
  audio_box: ^0.0.8
```

Then import it:

```dart
import 'package:audio_box/audio_box.dart';
```

## Usage

### 1. Register audio sources

```dart
await audioManager.registerAll({
  'bgm_menu': AssetAudioSource('assets/bgm/menu.mp3'),
  'se_click': AssetAudioSource('assets/se/click.wav'),
});
```

### 2. Play sound

```dart
await audioManager.play(key: 'se_click');
```

### 3. Play BGM with fade and loop

```dart
await audioManager.play(
  key: 'bgm_menu',
  channel: 'bgm',
  loop: true,
  fadeDuration: Duration(seconds: 2),
);
```

### 4. Set master volume

```dart
await audioManager.setMasterVolume(0.8);
```

## Example

Check out the [`/example`](example) folder for a full working example.

## License

This package is released under the [MIT License](LICENSE).  
Created by [take-p](https://github.com/take-p).