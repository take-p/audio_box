## 0.0.9
- SDKの最小バージョンを3.6.0に変更

## 0.0.8

### 変更点
- デフォルトの音量を微調整

### Changes
- Fine-tuned the default volume.

## 0.0.7

### 変更点
- マスターボリューム機能を追加

### Changes
- Added master volume functionality.

## 0.0.6

### 変更点
- フェードイン再生とフェードアウト停止をサポート

### Changes
- Added support for fade-in playback and fade-out stop.

## 0.0.5

### 変更点
- デフォルトで使用するパッケージを`just_audio`から`audioplayers`に変更
- サンプルアプリを`audioplayers`に合わせて修正

### Changes
- Changed the default package from `just_audio` to `audioplayers`.
- Updated the sample app to align with `audioplayers`.

## 0.0.4

### 変更点
- メソッド`setVolume`を`changeVolume`に改名。
- AudioRepositoryインターフェースとAudioBoxクラスで実装メソッドの引数の型に違いがあった点を修正

### Changes
- Renamed the method `setVolume` to `changeVolume`.
- Fixed argument type inconsistencies between `AudioRepository` interface and `AudioBox` class.

## 0.0.3

### 新機能
- `key` 引数の省略をサポートするように変更：
  - `stop`, `pause`, `resume`, `setVolume`, `changeSpeed` などのメソッドで、`channel` を指定していれば `key` の指定は不要になります。
  - `channel` も `key` も指定しない場合は、**全プレイヤーに対して操作**を行うようになりました。

### 互換性に関する注意
- `stop`, `pause`, `resume`, `setVolume`, `changeSpeed` で `key` と `channel` を同時指定すると `ArgumentError` が発生します。どちらか一方を指定してください。

### 内部改善
- `AudioRepository` のメソッドシグネチャを調整し、柔軟性を向上。
- コードの可読性と堅牢性を強化。

### New Features
- Added support for omitting the `key` argument:
  - If `channel` is specified, `key` is no longer required for methods like `stop`, `pause`, `resume`, `setVolume`, and `changeSpeed`.
  - If neither `channel` nor `key` is specified, operations will apply to **all players**.

### Compatibility Notes
- Specifying both `key` and `channel` simultaneously in `stop`, `pause`, `resume`, `setVolume`, and `changeSpeed` will throw an `ArgumentError`. Specify only one.

### Internal Improvements
- Adjusted method signatures in `AudioRepository` for greater flexibility.
- Improved code readability and robustness.

## 0.0.2

### 変更点
- Rename: Fixed leftover references from `AudioKit` to `AudioBox`.

### Changes
- Rename: Fixed leftover references from `AudioKit` to `AudioBox`.

## 0.0.1

### 初回リリース
- 初回リリース。

### Initial Release
- Initial release.