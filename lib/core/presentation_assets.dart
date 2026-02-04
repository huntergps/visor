/// Asset mapping for presentation types
class PresentationAssets {
  PresentationAssets._();

  /// Default asset when no match is found
  static const String defaultAsset = 'assets/empaque.png';

  /// Asset mappings by keyword
  static const Map<String, String> _assetMap = {
    'jaba': 'assets/jaba.png',
    'quintal': 'assets/quintal.png',
    'resma': 'assets/resma.png',
    'rollo': 'assets/rollo.png',
  };

  /// Get the asset path for a presentation label
  static String getAssetForLabel(String label) {
    final lowerLabel = label.toLowerCase();

    for (final entry in _assetMap.entries) {
      if (lowerLabel.contains(entry.key)) {
        return entry.value;
      }
    }

    return defaultAsset;
  }

  /// All available presentation asset paths
  static List<String> get allAssets => [
        ...PresentationAssets._assetMap.values,
        defaultAsset,
      ];
}
