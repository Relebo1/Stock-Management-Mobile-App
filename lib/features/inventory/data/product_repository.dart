import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/stock_product.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();
  static final List<StockProduct> _browserProducts = List.of(StockProducts.demo);
  static const _swatches = [0xFFDBEDE7, 0xFFF4E6D6, 0xFFFFE8D2, 0xFFECE8D9, 0xFFDCE9F1];

  Future<List<StockProduct>> getProducts() async {
    if (kIsWeb) return List.unmodifiable(_browserProducts);
    final db = await AppDatabase.instance.database;
    await _seedDemoProductsIfEmpty(db);
    final rows = await db.rawQuery('''
      SELECT p.id, p.name, p.sku, p.description, p.brand, p.unit_of_measure,
        p.cost_price, p.selling_price, p.minimum_stock_level, c.name AS category,
        COALESCE(b.quantity_on_hand, 0) AS quantity,
        (SELECT barcode FROM product_barcodes pb WHERE pb.product_id = p.id LIMIT 1) AS barcode
      FROM products p
      LEFT JOIN categories c ON c.id = p.category_id
      LEFT JOIN stock_balances b ON b.product_id = p.id AND b.business_id = p.business_id
        AND b.location_id = (SELECT id FROM locations WHERE business_id = p.business_id AND code = 'MAIN' LIMIT 1)
      WHERE p.business_id = (SELECT id FROM businesses ORDER BY id LIMIT 1)
      ORDER BY p.name COLLATE NOCASE
    ''');
    return rows.asMap().entries.map((entry) {
      final row = entry.value;
      return StockProduct(
        id: row['id'] as int,
        name: row['name'] as String,
        category: row['category'] as String? ?? 'Other',
        sku: row['sku'] as String,
        price: (row['selling_price'] as num).toDouble(),
        cost: (row['cost_price'] as num).toDouble(),
        quantity: (row['quantity'] as num).round(),
        minimumStock: (row['minimum_stock_level'] as num).round(),
        colorValue: _swatches[entry.key % _swatches.length],
        barcode: row['barcode'] as String? ?? '',
      );
    }).toList();
  }

  Future<StockProduct> addProduct(StockProduct product) async {
    if (kIsWeb) {
      _browserProducts.insert(0, product);
      return product;
    }
    final db = await AppDatabase.instance.database;
    final id = await db.transaction((txn) async {
      final businessId = await _defaultBusinessId(txn);
      final locationId = await _mainLocationId(txn, businessId);
      final categoryId = await _categoryId(txn, businessId, product.category);
      final now = DateTime.now().toUtc().toIso8601String();
      final productId = await txn.insert('products', {
        'business_id': businessId,
        'category_id': categoryId,
        'name': product.name,
        'sku': product.sku,
        'selling_price': product.price,
        'cost_price': product.cost,
        'minimum_stock_level': product.minimumStock,
        'status': 'ACTIVE',
        'created_at': now,
        'updated_at': now,
      });
      if (product.barcode.isNotEmpty) {
        await txn.insert('product_barcodes', {'business_id': businessId, 'product_id': productId, 'barcode': product.barcode, 'barcode_type': 'OTHER', 'created_at': now});
      }
      await txn.insert('stock_balances', {'business_id': businessId, 'product_id': productId, 'location_id': locationId, 'quantity_on_hand': product.quantity, 'updated_at': now});
      await _writeMovement(txn, businessId: businessId, productId: productId, locationId: locationId, change: product.quantity, before: 0, after: product.quantity, type: 'OPENING_STOCK', now: now);
      return productId;
    });
    return product.copyWith(id: id);
  }

  Future<int> adjustStock(StockProduct product, int newQuantity) async {
    if (newQuantity < 0) throw ArgumentError.value(newQuantity, 'newQuantity', 'Stock cannot be negative');
    if (kIsWeb || product.id == null) {
      final index = _browserProducts.indexWhere((item) => item.sku == product.sku);
      if (index >= 0) {
        final old = _browserProducts[index];
        _browserProducts[index] = StockProduct(id: old.id, name: old.name, category: old.category, sku: old.sku, price: old.price, cost: old.cost, quantity: newQuantity, minimumStock: old.minimumStock, colorValue: old.colorValue, barcode: old.barcode);
      }
      return newQuantity;
    }
    final db = await AppDatabase.instance.database;
    return db.transaction((txn) async {
      final businessId = await _defaultBusinessId(txn);
      final locationId = await _mainLocationId(txn, businessId);
      final rows = await txn.query('stock_balances', columns: ['id', 'quantity_on_hand'], where: 'business_id = ? AND product_id = ? AND location_id = ?', whereArgs: [businessId, product.id, locationId], limit: 1);
      final before = rows.isEmpty ? 0 : (rows.first['quantity_on_hand'] as num).round();
      if (before == newQuantity) return newQuantity;
      final change = newQuantity - before;
      final now = DateTime.now().toUtc().toIso8601String();
      if (rows.isEmpty) {
        await txn.insert('stock_balances', {'business_id': businessId, 'product_id': product.id, 'location_id': locationId, 'quantity_on_hand': newQuantity, 'updated_at': now});
      } else {
        await txn.update('stock_balances', {'quantity_on_hand': newQuantity, 'updated_at': now}, where: 'id = ?', whereArgs: [rows.first['id']]);
      }
      final userId = await _defaultUserId(txn);
      final adjustmentId = await txn.insert('stock_adjustments', {
        'business_id': businessId,
        'location_id': locationId,
        'adjustment_number': 'ADJ-${DateTime.now().microsecondsSinceEpoch}',
        'reason': 'Manual stock adjustment',
        'status': 'COMPLETED',
        'created_by': userId,
        'created_at': now,
      });
      await txn.insert('stock_adjustment_items', {'adjustment_id': adjustmentId, 'product_id': product.id, 'quantity_before': before, 'actual_quantity': newQuantity, 'quantity_change': change});
      await _writeMovement(txn, businessId: businessId, productId: product.id!, locationId: locationId, change: change, before: before, after: newQuantity, type: 'ADJUSTMENT', now: now);
      return newQuantity;
    });
  }

  Future<void> _seedDemoProductsIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM products')) ?? 0;
    if (count > 0) return;
    await db.transaction((txn) async {
      final businessId = await _defaultBusinessId(txn);
      final locationId = await _mainLocationId(txn, businessId);
      for (final product in StockProducts.demo) {
        final categoryId = await _categoryId(txn, businessId, product.category);
        final now = DateTime.now().toUtc().toIso8601String();
        final id = await txn.insert('products', {'business_id': businessId, 'category_id': categoryId, 'name': product.name, 'sku': product.sku, 'cost_price': product.cost, 'selling_price': product.price, 'minimum_stock_level': product.minimumStock, 'status': 'ACTIVE', 'created_at': now, 'updated_at': now});
        await txn.insert('stock_balances', {'business_id': businessId, 'product_id': id, 'location_id': locationId, 'quantity_on_hand': product.quantity, 'updated_at': now});
        await _writeMovement(txn, businessId: businessId, productId: id, locationId: locationId, change: product.quantity, before: 0, after: product.quantity, type: 'OPENING_STOCK', now: now);
      }
    });
  }

  Future<int> _defaultBusinessId(DatabaseExecutor db) async {
    final rows = await db.query('businesses', columns: ['id'], orderBy: 'id', limit: 1);
    if (rows.isEmpty) throw StateError('No StockMate business is configured');
    return rows.first['id'] as int;
  }

  Future<int> _defaultUserId(DatabaseExecutor db) async {
    final rows = await db.query('users', columns: ['id'], where: 'email = ?', whereArgs: ['demo@stockmate.local'], limit: 1);
    if (rows.isEmpty) throw StateError('No active StockMate user is configured');
    return rows.first['id'] as int;
  }

  Future<int> _mainLocationId(DatabaseExecutor db, int businessId) async {
    final rows = await db.query('locations', columns: ['id'], where: 'business_id = ? AND code = ?', whereArgs: [businessId, 'MAIN'], limit: 1);
    if (rows.isEmpty) throw StateError('The main stock location is missing');
    return rows.first['id'] as int;
  }

  Future<int> _categoryId(DatabaseExecutor db, int businessId, String name) async {
    final rows = await db.query('categories', columns: ['id'], where: 'business_id = ? AND name = ?', whereArgs: [businessId, name], limit: 1);
    if (rows.isNotEmpty) return rows.first['id'] as int;
    return db.insert('categories', {'business_id': businessId, 'name': name, 'status': 'ACTIVE', 'created_at': DateTime.now().toUtc().toIso8601String()});
  }

  Future<void> _writeMovement(DatabaseExecutor db, {required int businessId, required int productId, required int locationId, required int change, required int before, required int after, required String type, required String now}) async {
    await db.insert('stock_movements', {'business_id': businessId, 'product_id': productId, 'location_id': locationId, 'movement_type': type, 'quantity_change': change, 'quantity_before': before, 'quantity_after': after, 'reference_type': type == 'ADJUSTMENT' ? 'STOCK_ADJUSTMENT' : 'PRODUCT', 'created_by': await _defaultUserId(db), 'created_at': now});
  }
}
