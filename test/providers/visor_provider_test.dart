import 'package:flutter_test/flutter_test.dart';
import 'package:visor/providers/visor_provider.dart';

void main() {
  group('VisorProvider', () {
    late VisorProvider provider;

    setUp(() {
      provider = VisorProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state is product view with welcome message', () {
      expect(provider.viewState, VisorViewState.product);
      expect(provider.currentProduct.name, 'BIENVENIDO');
      expect(provider.currentProduct.barcode, '');
      expect(provider.searchState, SearchState.idle);
    });

    test('showAdsView switches to ads view', () {
      provider.showAdsView();
      expect(provider.viewState, VisorViewState.ads);
    });

    test('errorMessage is initially null', () {
      expect(provider.errorMessage, isNull);
    });
  });

  group('VisorViewState', () {
    test('has correct values', () {
      expect(VisorViewState.values.length, 2);
      expect(VisorViewState.product.index, 0);
      expect(VisorViewState.ads.index, 1);
    });
  });

  group('SearchState', () {
    test('has correct values', () {
      expect(SearchState.values.length, 5);
      expect(SearchState.idle.index, 0);
      expect(SearchState.loading.index, 1);
      expect(SearchState.success.index, 2);
      expect(SearchState.notFound.index, 3);
      expect(SearchState.error.index, 4);
    });
  });
}
