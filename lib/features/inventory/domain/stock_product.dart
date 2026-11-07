class StockProduct {
  const StockProduct({
    this.id,
    required this.name,
    required this.category,
    required this.sku,
    required this.price,
    required this.quantity,
    required this.minimumStock,
    required this.colorValue,
    this.barcode = '',
    this.cost = 0,
  });

  final int? id;
  final String name;
  final String category;
  final String sku;
  final double price;
  final int quantity;
  final int minimumStock;
  final int colorValue;
  final String barcode;
  final double cost;

  StockProduct copyWith({int? id}) => StockProduct(
        id: id ?? this.id,
        name: name,
        category: category,
        sku: sku,
        price: price,
        quantity: quantity,
        minimumStock: minimumStock,
        colorValue: colorValue,
        barcode: barcode,
        cost: cost,
      );

  bool get isOutOfStock => quantity <= 0;
  bool get isLowStock => !isOutOfStock && quantity <= minimumStock;
}

class StockProducts {
  static final List<StockProduct> demo = [
    const StockProduct(name: 'Fresh Milk 1L', category: 'Dairy', sku: 'DAI-001', price: 18.50, quantity: 4, minimumStock: 8, colorValue: 0xFFDBEDE7),
    const StockProduct(name: 'Brown Bread', category: 'Bakery', sku: 'BAK-014', price: 15, quantity: 0, minimumStock: 6, colorValue: 0xFFF4E6D6),
    const StockProduct(name: 'Orange Juice', category: 'Drinks', sku: 'DRK-032', price: 24, quantity: 12, minimumStock: 5, colorValue: 0xFFFFE8D2),
    const StockProduct(name: 'Rice 2kg', category: 'Groceries', sku: 'GRO-008', price: 42, quantity: 3, minimumStock: 5, colorValue: 0xFFECE8D9),
    const StockProduct(name: 'Dish Soap', category: 'Household', sku: 'HOU-021', price: 29.99, quantity: 18, minimumStock: 4, colorValue: 0xFFDCE9F1),
  ];
}
