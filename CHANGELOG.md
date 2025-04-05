## 0.0.1
- Initial release
## [0.0.2] - 2025-04-05
- Rename: Fixed leftover references from `AudioKit` to `AudioBox`
## [0.0.3] - 2025-04-05

### ✨ 新機能
- `key` 引数の省略をサポートするように変更：
    - `stop`, `pause`, `resume`, `setVolume`, `changeSpeed` などのメソッドで、`channel` を指定していれば `key` の指定は不要になります。
    - `channel` も `key` も指定しない場合は、**全プレイヤーに対して操作**を行うようになりました。

### ⚠️ 互換性に関する注意
- `stop`, `pause`, `resume`, `setVolume`, `changeSpeed` で `key` と `channel` を同時指定すると `ArgumentError` が発生します。どちらか一方を指定してください。

### 🧼 内部改善
- `AudioRepository` のメソッドシグネチャを調整し、柔軟性を向上。
- コードの可読性と堅牢性を強化。