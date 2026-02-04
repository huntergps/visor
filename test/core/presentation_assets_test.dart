import 'package:flutter_test/flutter_test.dart';
import 'package:visor/core/presentation_assets.dart';

void main() {
  group('PresentationAssets', () {
    test('returns jaba asset for label containing jaba', () {
      expect(
        PresentationAssets.getAssetForLabel('JABA X 12'),
        'assets/jaba.png',
      );
      expect(
        PresentationAssets.getAssetForLabel('jaba'),
        'assets/jaba.png',
      );
      expect(
        PresentationAssets.getAssetForLabel('JABA DE CERVEZA'),
        'assets/jaba.png',
      );
    });

    test('returns quintal asset for label containing quintal', () {
      expect(
        PresentationAssets.getAssetForLabel('QUINTAL X 100'),
        'assets/quintal.png',
      );
      expect(
        PresentationAssets.getAssetForLabel('quintal'),
        'assets/quintal.png',
      );
    });

    test('returns resma asset for label containing resma', () {
      expect(
        PresentationAssets.getAssetForLabel('RESMA X 500'),
        'assets/resma.png',
      );
      expect(
        PresentationAssets.getAssetForLabel('resma de papel'),
        'assets/resma.png',
      );
    });

    test('returns rollo asset for label containing rollo', () {
      expect(
        PresentationAssets.getAssetForLabel('ROLLO X 50'),
        'assets/rollo.png',
      );
      expect(
        PresentationAssets.getAssetForLabel('rollo grande'),
        'assets/rollo.png',
      );
    });

    test('returns default asset for unrecognized labels', () {
      expect(
        PresentationAssets.getAssetForLabel('CAJA X 24'),
        'assets/empaque.png',
      );
      expect(
        PresentationAssets.getAssetForLabel('PAQUETE'),
        'assets/empaque.png',
      );
      expect(
        PresentationAssets.getAssetForLabel(''),
        'assets/empaque.png',
      );
      expect(
        PresentationAssets.getAssetForLabel('UNKNOWN'),
        'assets/empaque.png',
      );
    });

    test('defaultAsset is empaque.png', () {
      expect(PresentationAssets.defaultAsset, 'assets/empaque.png');
    });

    test('allAssets contains all expected assets', () {
      final assets = PresentationAssets.allAssets;

      expect(assets, contains('assets/jaba.png'));
      expect(assets, contains('assets/quintal.png'));
      expect(assets, contains('assets/resma.png'));
      expect(assets, contains('assets/rollo.png'));
      expect(assets, contains('assets/empaque.png'));
      expect(assets.length, 5);
    });

    test('is case insensitive', () {
      expect(
        PresentationAssets.getAssetForLabel('JABA'),
        PresentationAssets.getAssetForLabel('jaba'),
      );
      expect(
        PresentationAssets.getAssetForLabel('QUINTAL'),
        PresentationAssets.getAssetForLabel('Quintal'),
      );
    });
  });
}
