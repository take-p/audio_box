abstract class AudioSourceEntry {
  const AudioSourceEntry();
}

class AssetAudioSource extends AudioSourceEntry {
  final String assetPath;
  const AssetAudioSource(this.assetPath);
}

class FileAudioSource extends AudioSourceEntry {
  final String filePath;
  const FileAudioSource(this.filePath);
}

class UrlAudioSource extends AudioSourceEntry {
  final String url;
  const UrlAudioSource(this.url);
}
