/// Data models mirroring the createcart-api JSON shapes.

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class MenuItem {
  final String id;
  final String name;
  final String? nameLocalized;
  final String description;
  final double price;
  final String currency;
  final String? imageUrl;
  final String? icon;
  final String? category;
  final List<String> tags;
  final bool available;
  final int? stock;

  MenuItem({
    required this.id,
    required this.name,
    this.nameLocalized,
    this.description = '',
    this.price = 0,
    this.currency = 'INR',
    this.imageUrl,
    this.icon,
    this.category,
    this.tags = const [],
    this.available = true,
    this.stock,
  });

  /// In stock + available to sell.
  bool get sellable => available && (stock == null || stock! > 0);

  factory MenuItem.fromJson(Map<String, dynamic> j) => MenuItem(
        id: j['id'].toString(),
        name: (j['name'] ?? '').toString(),
        nameLocalized: j['name_localized']?.toString(),
        description: (j['description'] ?? '').toString(),
        price: _toDouble(j['price']),
        currency: (j['currency'] ?? 'INR').toString(),
        imageUrl: (j['image_url'] == null || '${j['image_url']}'.isEmpty)
            ? null
            : j['image_url'].toString(),
        icon: j['icon']?.toString(),
        category: j['category']?.toString(),
        tags: (j['tags'] is List)
            ? (j['tags'] as List).map((e) => e.toString()).toList()
            : const [],
        available: j['available'] == true || j['available'] == 1,
        stock: j['stock'] == null ? null : _toInt(j['stock']),
      );
}

class CartLine {
  final String itemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final String? icon;

  CartLine({
    required this.itemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.icon,
  });

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        itemId: (j['item_id'] ?? j['id']).toString(),
        name: (j['name'] ?? '').toString(),
        unitPrice: _toDouble(j['unit_price']),
        quantity: _toInt(j['quantity']),
        lineTotal: _toDouble(j['line_total']),
        icon: j['icon']?.toString(),
      );

  CartLine copyWith({int? quantity}) => CartLine(
        itemId: itemId,
        name: name,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        lineTotal: unitPrice * (quantity ?? this.quantity),
        icon: icon,
      );
}

class CartTotals {
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double chargesTotal;
  final double grandTotal;
  final int totalQuantity;

  CartTotals({
    this.subtotal = 0,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.chargesTotal = 0,
    this.grandTotal = 0,
    this.totalQuantity = 0,
  });

  factory CartTotals.fromJson(Map<String, dynamic>? j) {
    j ??= {};
    return CartTotals(
      subtotal: _toDouble(j['subtotal']),
      discountTotal: _toDouble(j['discount_total']),
      taxTotal: _toDouble(j['tax_total']),
      chargesTotal: _toDouble(j['charges_total']),
      grandTotal: _toDouble(j['grand_total']),
      totalQuantity: _toInt(j['total_quantity']),
    );
  }
}

class CartView {
  final List<CartLine> items;
  final CartTotals totals;

  CartView({this.items = const [], CartTotals? totals})
      : totals = totals ?? CartTotals();

  factory CartView.fromJson(dynamic j) {
    if (j is! Map) return CartView();
    final items = (j['items'] is List)
        ? (j['items'] as List)
            .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
            .toList()
        : <CartLine>[];
    return CartView(items: items, totals: CartTotals.fromJson(j['totals']));
  }

  static CartView empty() => CartView();
}
