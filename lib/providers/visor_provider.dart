import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/app_config_service.dart';
import '../services/product_service.dart';
import '../services/visor_config_service.dart';

/// Visor state for UI
enum VisorViewState {
  product,
  ads,
}

/// Search state
enum SearchState {
  idle,
  loading,
  success,
  notFound,
  error,
}

/// Centralized state management for the Visor application
class VisorProvider extends ChangeNotifier {
  final ProductService _productService;

  VisorProvider({ProductService? productService})
      : _productService = productService ?? ProductService();

  // Current view state
  VisorViewState _viewState = VisorViewState.product;
  VisorViewState get viewState => _viewState;

  // Search state
  SearchState _searchState = SearchState.idle;
  SearchState get searchState => _searchState;

  // Current product
  Product _currentProduct = Product(
    name: 'BIENVENIDO',
    barcode: '',
    stock: 0,
    regularPrice: 0.0,
    finalPrice: 0.0,
    imageUrl: 'assets/no_imagen.png',
  );
  Product get currentProduct => _currentProduct;

  // Error message if any
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Image loading state
  bool _imageLoading = false;
  bool get imageLoading => _imageLoading;

  // Idle timer
  Timer? _idleTimer;

  // Cached idle timeout (avoid reading SharedPrefs every time)
  int _cachedIdleTimeout = 60;

  // Track if disposed to prevent timer callbacks on disposed provider
  bool _isDisposed = false;

  /// Initialize the provider and start idle timer
  void initialize() {
    _loadCachedConfig();
    _resetIdleTimer();
  }

  /// Load config values into memory cache
  void _loadCachedConfig() {
    final config = VisorConfigService().getConfig();
    _cachedIdleTimeout = (config.tiempoEspera > 0)
        ? config.tiempoEspera
        : AppConfigService().idleTimeout;
  }

  /// Refresh cached config (call after config changes)
  void refreshConfig() {
    _loadCachedConfig();
  }

  /// Search for a product by barcode
  Future<void> searchProduct(String barcode) async {
    final query = barcode.trim();
    if (query.isEmpty) return;

    _resetIdleTimer();

    // Only notify if state actually changes
    if (_searchState != SearchState.loading) {
      _searchState = SearchState.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Check if server is configured
      final appConfig = AppConfigService();
      if (appConfig.host.isEmpty) {
        _currentProduct = Product(
          name: 'SERVIDOR NO CONFIGURADO',
          barcode: query,
          stock: 0,
          imageUrl: 'assets/no_imagen.png',
          regularPrice: 0.0,
          finalPrice: 0.0,
        );
        _searchState = SearchState.error;
        _errorMessage = 'Configure el host del servidor en ajustes (doble-tap en "confianza")';
        _viewState = VisorViewState.product;
        notifyListeners();
        return;
      }

      final result = await _productService.getProductByBarcode(query);

      if (result != null) {
        _currentProduct = result.product;
        _searchState = SearchState.success;
        _viewState = VisorViewState.product;
        _imageLoading = result.pendingImage != null;
        notifyListeners(); // Show data immediately

        // Load image in background if pending
        if (result.pendingImage != null) {
          final imageSource = await result.pendingImage;
          if (!_isDisposed &&
              _currentProduct.barcode == result.product.barcode) {
            _imageLoading = false;
            if (imageSource != null) {
              _currentProduct = result.product.copyWithImageUrl(imageSource);
            }
            notifyListeners();
          }
        }
      } else {
        _currentProduct = Product(
          name: 'PRODUCTO NO ENCONTRADO',
          barcode: query,
          stock: 0,
          imageUrl: 'assets/no_imagen.png',
          regularPrice: 0.0,
          finalPrice: 0.0,
          discounts: const [],
          presentations: const [],
        );
        _searchState = SearchState.notFound;
        _viewState = VisorViewState.product;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error searching product: $e');
      _errorMessage = e.toString();
      _searchState = SearchState.error;
      notifyListeners();
    }
  }

  /// Reset product to welcome state
  void resetProduct() {
    _currentProduct = Product(
      name: 'BIENVENIDO',
      barcode: '',
      stock: 0,
      regularPrice: 0.0,
      finalPrice: 0.0,
      imageUrl: 'assets/no_imagen.png',
    );
    _searchState = SearchState.idle;
    _imageLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Switch to product view from ads
  void showProductView() {
    _resetIdleTimer();
    if (_viewState == VisorViewState.ads) {
      _viewState = VisorViewState.product;
      notifyListeners();
    }
  }

  /// Switch to ads view and reset product state
  void showAdsView() {
    if (_isDisposed) return;
    _currentProduct = Product(
      name: 'BIENVENIDO',
      barcode: '',
      stock: 0,
      regularPrice: 0.0,
      finalPrice: 0.0,
      imageUrl: 'assets/no_imagen.png',
    );
    _searchState = SearchState.idle;
    _imageLoading = false;
    _errorMessage = null;
    _viewState = VisorViewState.ads;
    notifyListeners();
  }

  /// Reset the idle timer using cached timeout value
  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (_isDisposed) return;
    _idleTimer = Timer(Duration(seconds: _cachedIdleTimeout), () {
      if (!_isDisposed) {
        showAdsView();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _idleTimer?.cancel();
    _idleTimer = null;
    super.dispose();
  }
}
