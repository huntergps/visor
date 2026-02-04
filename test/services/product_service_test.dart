import 'package:flutter_test/flutter_test.dart';
import 'package:visor/models/product.dart';
import 'package:visor/models/presentation_price.dart';
import 'package:visor/models/discount.dart';

// Test helper to simulate ProductService._mapJsonToProduct behavior
// Since the method is private, we test the same logic externally
Product mapJsonToProduct(Map<String, dynamic> json) {
  final preciosList = json['precios'] as List? ?? [];
  final parseResult = _parsePricesList(preciosList);
  final regularPrice = parseResult.mainPrice + parseResult.discountAmount;

  return Product(
    name: json['name'] ?? 'Desconocido',
    barcode: json['codigo'] ?? '',
    family: json['familia'] ?? '',
    stock: 10,
    regularPrice: regularPrice,
    finalPrice: parseResult.mainPrice,
    unitLabel: parseResult.unitLabel,
    taxPercent: 0.0,
    discounts: parseResult.discounts,
    imageUrl: _extractNonEmpty(json['imagen']),
    imageBase64: _extractNonEmpty(json['imagen64']),
    presentations: parseResult.presentations,
  );
}

String? _extractNonEmpty(dynamic value) {
  if (value == null) return null;
  final str = value.toString();
  return str.isNotEmpty ? str : null;
}

_PricesParseResult _parsePricesList(List<dynamic> preciosList) {
  double mainPrice = 0.0;
  double discountAmount = 0.0;
  String unitLabel = '';
  List<PresentationPrice> presentations = [];
  List<Discount> discounts = [];
  bool foundMainPrice = false;

  for (var p in preciosList) {
    if (p is! Map) continue;

    final pvp = _parseDouble(p['PVP']);
    final name = p['name']?.toString() ?? '';
    final factor = _parseDouble(p['factor']);
    final discountPercent = _parseDouble(p['descuento']);
    final itemDiscountAmount = _parseDouble(p['descuento_monto']);

    final isMainUnit = _isMainUnit(factor, name);

    if (isMainUnit && !foundMainPrice) {
      mainPrice = pvp;
      discountAmount = itemDiscountAmount;
      unitLabel = _cleanUnitLabel(name);
      foundMainPrice = true;

      if (discountPercent > 0) {
        discounts.add(Discount(
          percent: discountPercent,
          amount: itemDiscountAmount,
          conditionsText: 'Descuento directo',
        ));
      }
    } else if (!isMainUnit) {
      presentations.add(PresentationPrice(
        label: name,
        price: pvp,
        discountPercent: discountPercent,
        discountAmount: itemDiscountAmount,
      ));
    }
  }

  if (!foundMainPrice && preciosList.isNotEmpty && preciosList[0] is Map) {
    mainPrice = _parseDouble(preciosList[0]['PVP']);
  }

  return _PricesParseResult(
    mainPrice: mainPrice,
    discountAmount: discountAmount,
    unitLabel: unitLabel,
    presentations: presentations,
    discounts: discounts,
  );
}

bool _isMainUnit(double factor, String name) {
  return factor == 1.0 || name.toUpperCase().contains('UNIDAD');
}

String _cleanUnitLabel(String name) {
  final rawName = name.toUpperCase();
  if (rawName.contains(' X 1')) {
    return rawName.replaceAll(' X 1', '').trim();
  }
  return name;
}

double _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return 0.0;
}

class _PricesParseResult {
  final double mainPrice;
  final double discountAmount;
  final String unitLabel;
  final List<PresentationPrice> presentations;
  final List<Discount> discounts;

  const _PricesParseResult({
    required this.mainPrice,
    required this.discountAmount,
    required this.unitLabel,
    required this.presentations,
    required this.discounts,
  });
}

void main() {
  group('ProductService JSON Parsing', () {
    test('parses basic product with single price', () {
      final json = {
        'name': 'Test Product',
        'codigo': 'ABC123',
        'familia': 'Test Family',
        'imagen': 'http://example.com/image.png',
        'precios': [
          {
            'name': 'UNIDAD X 1',
            'PVP': 10.50,
            'factor': 1.0,
            'descuento': 0.0,
            'descuento_monto': 0.0,
          }
        ],
      };

      final product = mapJsonToProduct(json);

      expect(product.name, 'Test Product');
      expect(product.barcode, 'ABC123');
      expect(product.family, 'Test Family');
      expect(product.finalPrice, 10.50);
      expect(product.regularPrice, 10.50);
      expect(product.unitLabel, 'UNIDAD');
      expect(product.discounts, isEmpty);
      expect(product.presentations, isEmpty);
      expect(product.imageUrl, 'http://example.com/image.png');
    });

    test('parses product with discount', () {
      final json = {
        'name': 'Discounted Product',
        'codigo': 'DISC001',
        'precios': [
          {
            'name': 'UNIDAD X 1',
            'PVP': 8.50,
            'factor': 1.0,
            'descuento': 15.0,
            'descuento_monto': 1.50,
          }
        ],
      };

      final product = mapJsonToProduct(json);

      expect(product.finalPrice, 8.50);
      expect(product.regularPrice, 10.0); // 8.50 + 1.50
      expect(product.discounts.length, 1);
      expect(product.discounts[0].percent, 15.0);
      expect(product.discounts[0].amount, 1.50);
    });

    test('parses product with multiple presentations', () {
      final json = {
        'name': 'Multi Presentation Product',
        'codigo': 'MULTI001',
        'precios': [
          {
            'name': 'UNIDAD X 1',
            'PVP': 5.00,
            'factor': 1.0,
            'descuento': 0.0,
            'descuento_monto': 0.0,
          },
          {
            'name': 'JABA X 12',
            'PVP': 55.00,
            'factor': 12.0,
            'descuento': 8.0,
            'descuento_monto': 5.00,
          },
          {
            'name': 'QUINTAL X 100',
            'PVP': 450.00,
            'factor': 100.0,
            'descuento': 10.0,
            'descuento_monto': 50.00,
          },
        ],
      };

      final product = mapJsonToProduct(json);

      expect(product.finalPrice, 5.00);
      expect(product.presentations.length, 2);

      final jaba = product.presentations[0];
      expect(jaba.label, 'JABA X 12');
      expect(jaba.price, 55.00);
      expect(jaba.discountPercent, 8.0);

      final quintal = product.presentations[1];
      expect(quintal.label, 'QUINTAL X 100');
      expect(quintal.price, 450.00);
      expect(quintal.discountPercent, 10.0);
    });

    test('uses first price as fallback when no main unit found', () {
      final json = {
        'name': 'No Unit Product',
        'codigo': 'NOUNIT001',
        'precios': [
          {
            'name': 'CAJA X 24',
            'PVP': 120.00,
            'factor': 24.0,
          },
        ],
      };

      final product = mapJsonToProduct(json);

      expect(product.finalPrice, 120.00);
      expect(product.presentations.length, 1);
    });

    test('handles empty precios list', () {
      final json = {
        'name': 'Empty Prices Product',
        'codigo': 'EMPTY001',
        'precios': [],
      };

      final product = mapJsonToProduct(json);

      expect(product.finalPrice, 0.0);
      expect(product.regularPrice, 0.0);
      expect(product.presentations, isEmpty);
    });

    test('handles missing precios field', () {
      final json = {
        'name': 'No Prices Product',
        'codigo': 'NOPRICES001',
      };

      final product = mapJsonToProduct(json);

      expect(product.finalPrice, 0.0);
      expect(product.name, 'No Prices Product');
    });

    test('handles null and empty imagen fields', () {
      final jsonWithNull = {
        'name': 'Test',
        'codigo': 'T1',
        'imagen': null,
        'imagen64': '',
        'precios': [],
      };

      final product = mapJsonToProduct(jsonWithNull);

      expect(product.imageUrl, isNull);
      expect(product.imageBase64, isNull);
    });

    test('cleans unit label correctly', () {
      expect(_cleanUnitLabel('UNIDAD X 1'), 'UNIDAD');
      expect(_cleanUnitLabel('LIBRA X 1'), 'LIBRA');
      expect(_cleanUnitLabel('UNIDAD'), 'UNIDAD');
      expect(_cleanUnitLabel('CAJA'), 'CAJA');
    });

    test('identifies main unit correctly', () {
      expect(_isMainUnit(1.0, 'UNIDAD X 1'), true);
      expect(_isMainUnit(1.0, 'LIBRA X 1'), true);
      expect(_isMainUnit(0.0, 'UNIDAD'), true);
      expect(_isMainUnit(12.0, 'CAJA X 12'), false);
      expect(_isMainUnit(0.0, 'JABA'), false);
    });

    test('parses double values safely', () {
      expect(_parseDouble(10), 10.0);
      expect(_parseDouble(10.5), 10.5);
      expect(_parseDouble(null), 0.0);
      expect(_parseDouble('string'), 0.0);
    });
  });
}
