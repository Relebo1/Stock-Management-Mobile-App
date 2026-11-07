import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens and migrates StockMate's on-device SQLite database.
/// Monetary and quantity fields use SQLite NUMERIC affinity; timestamps use ISO-8601 TEXT.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _fileName = 'stockmate.db';
  static const _version = 4;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      p.join(directory, _fileName),
      version: _version,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await _createSchema(db, version);
        await _seedDefaultAccount(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE users ADD COLUMN username TEXT');
          await db.execute('CREATE UNIQUE INDEX idx_users_username ON users(username COLLATE NOCASE) WHERE username IS NOT NULL');
          await db.update('users', {'username': 'demo'}, where: 'email = ?', whereArgs: ['demo@stockmate.local']);
        }
        if (oldVersion < 2) await _seedDefaultAccount(db);
        if (oldVersion >= 2 && oldVersion < 3) {
          final businesses = await db.query('businesses', columns: ['id'], limit: 1);
          if (businesses.isNotEmpty) {
            final existingLocation = await db.query('locations', columns: ['id'], where: 'business_id = ?', whereArgs: [businesses.first['id']], limit: 1);
            if (existingLocation.isEmpty) {
              await db.insert('locations', {'business_id': businesses.first['id'], 'name': 'Main location', 'code': 'MAIN', 'status': 'ACTIVE', 'created_at': DateTime.now().toUtc().toIso8601String()});
            }
          }
        }
      },
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    for (final statement in _schema) {
      await db.execute(statement);
    }
  }

  Future<void> _seedDefaultAccount(DatabaseExecutor db) async {
    final existing = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: ['demo@stockmate.local'],
      limit: 1,
    );
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final businessId = await db.insert('businesses', {
      'name': 'StockMate Demo Business',
      'business_type': 'RETAIL',
      'email': 'demo@stockmate.local',
      'currency': 'LSL',
      'status': 'ACTIVE',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('business_settings', {'business_id': businessId});
    await db.insert('locations', {
      'business_id': businessId,
      'name': 'Main location',
      'code': 'MAIN',
      'status': 'ACTIVE',
      'created_at': now,
    });

    final roleId = await db.insert('roles', {
      'business_id': businessId,
      'name': 'OWNER',
      'description': 'Business owner',
      'is_system': 0,
      'created_at': now,
    });
    final userId = await db.insert('users', {
      'username': 'demo',
      'first_name': 'Demo',
      'last_name': 'Owner',
      'email': 'demo@stockmate.local',
      // Passwords are not checked in prototype mode. Never use this record for production auth.
      'password': '!prototype-password-unused!',
      'email_verified': 1,
      'status': 'ACTIVE',
      'created_at': now,
      'updated_at': now,
    });
    await db.insert('business_users', {
      'business_id': businessId,
      'user_id': userId,
      'role_id': roleId,
      'status': 'ACTIVE',
      'joined_at': now,
    });
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

const List<String> _schema = [
  '''CREATE TABLE businesses (
    id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, business_type TEXT,
    registration_number TEXT, email TEXT, phone TEXT, address TEXT, currency TEXT NOT NULL DEFAULT 'LSL',
    status TEXT NOT NULL DEFAULT 'ACTIVE', created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
  '''CREATE TABLE business_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL UNIQUE REFERENCES businesses(id),
    tax_enabled INTEGER NOT NULL DEFAULT 0, default_tax_rate NUMERIC NOT NULL DEFAULT 0,
    low_stock_notifications INTEGER NOT NULL DEFAULT 1, sku_prefix TEXT, receipt_prefix TEXT, purchase_prefix TEXT)''',
  '''CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT NOT NULL COLLATE NOCASE UNIQUE,
    first_name TEXT NOT NULL, last_name TEXT NOT NULL,
    email TEXT NOT NULL COLLATE NOCASE UNIQUE, phone TEXT, password TEXT NOT NULL,
    profile_image TEXT, email_verified INTEGER NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'ACTIVE',
    created_at TEXT NOT NULL, updated_at TEXT NOT NULL)''',
  '''CREATE TABLE roles (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER REFERENCES businesses(id), name TEXT NOT NULL,
    description TEXT, is_system INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL,
    UNIQUE(business_id, name))''',
  '''CREATE TABLE permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT NOT NULL UNIQUE, description TEXT)''',
  '''CREATE TABLE business_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    user_id INTEGER NOT NULL REFERENCES users(id), role_id INTEGER NOT NULL REFERENCES roles(id),
    status TEXT NOT NULL DEFAULT 'ACTIVE', joined_at TEXT, UNIQUE(business_id, user_id))''',
  '''CREATE TABLE role_permissions (
    id INTEGER PRIMARY KEY AUTOINCREMENT, role_id INTEGER NOT NULL REFERENCES roles(id),
    permission_id INTEGER NOT NULL REFERENCES permissions(id), UNIQUE(role_id, permission_id))''',
  '''CREATE TABLE user_invitations (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    email TEXT NOT NULL COLLATE NOCASE, role_id INTEGER NOT NULL REFERENCES roles(id), token_hash TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING', expires_at TEXT NOT NULL, invited_by INTEGER NOT NULL REFERENCES users(id),
    created_at TEXT NOT NULL)''',
  '''CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    name TEXT NOT NULL, description TEXT, parent_id INTEGER REFERENCES categories(id),
    status TEXT NOT NULL DEFAULT 'ACTIVE', created_at TEXT NOT NULL)''',
  '''CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    category_id INTEGER REFERENCES categories(id), name TEXT NOT NULL, sku TEXT NOT NULL, description TEXT,
    brand TEXT, unit_of_measure TEXT NOT NULL DEFAULT 'unit', cost_price NUMERIC NOT NULL DEFAULT 0,
    selling_price NUMERIC NOT NULL DEFAULT 0, minimum_stock_level NUMERIC NOT NULL DEFAULT 0, image_url TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE', created_at TEXT NOT NULL, updated_at TEXT NOT NULL,
    UNIQUE(business_id, sku))''',
  '''CREATE TABLE product_barcodes (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    product_id INTEGER NOT NULL REFERENCES products(id), barcode TEXT NOT NULL, barcode_type TEXT,
    created_at TEXT NOT NULL, UNIQUE(business_id, barcode))''',
  '''CREATE TABLE suppliers (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    name TEXT NOT NULL, contact_person TEXT, email TEXT, phone TEXT, address TEXT,
    status TEXT NOT NULL DEFAULT 'ACTIVE', created_at TEXT NOT NULL)''',
  '''CREATE TABLE supplier_products (
    id INTEGER PRIMARY KEY AUTOINCREMENT, supplier_id INTEGER NOT NULL REFERENCES suppliers(id),
    product_id INTEGER NOT NULL REFERENCES products(id), supplier_product_code TEXT,
    last_purchase_price NUMERIC NOT NULL DEFAULT 0, UNIQUE(supplier_id, product_id))''',
  '''CREATE TABLE locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    name TEXT NOT NULL, code TEXT, address TEXT, status TEXT NOT NULL DEFAULT 'ACTIVE', created_at TEXT NOT NULL,
    UNIQUE(business_id, code))''',
  '''CREATE TABLE stock_balances (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    product_id INTEGER NOT NULL REFERENCES products(id), location_id INTEGER NOT NULL REFERENCES locations(id),
    quantity_on_hand NUMERIC NOT NULL DEFAULT 0, updated_at TEXT NOT NULL,
    UNIQUE(business_id, product_id, location_id))''',
  '''CREATE TABLE stock_movements (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    product_id INTEGER NOT NULL REFERENCES products(id), location_id INTEGER NOT NULL REFERENCES locations(id),
    movement_type TEXT NOT NULL, quantity_change NUMERIC NOT NULL, quantity_before NUMERIC NOT NULL,
    quantity_after NUMERIC NOT NULL, reference_type TEXT, reference_id INTEGER, reason TEXT,
    created_by INTEGER REFERENCES users(id), created_at TEXT NOT NULL)''',
  '''CREATE TRIGGER stock_movements_no_update BEFORE UPDATE ON stock_movements
    BEGIN SELECT RAISE(ABORT, 'stock movements are immutable'); END''',
  '''CREATE TRIGGER stock_movements_no_delete BEFORE DELETE ON stock_movements
    BEGIN SELECT RAISE(ABORT, 'stock movements are immutable'); END''',
  '''CREATE TABLE stock_adjustments (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    location_id INTEGER NOT NULL REFERENCES locations(id), adjustment_number TEXT NOT NULL,
    reason TEXT, status TEXT NOT NULL DEFAULT 'DRAFT', created_by INTEGER NOT NULL REFERENCES users(id),
    approved_by INTEGER REFERENCES users(id), created_at TEXT NOT NULL)''',
  '''CREATE TABLE stock_adjustment_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT, adjustment_id INTEGER NOT NULL REFERENCES stock_adjustments(id),
    product_id INTEGER NOT NULL REFERENCES products(id), quantity_before NUMERIC NOT NULL,
    actual_quantity NUMERIC NOT NULL, quantity_change NUMERIC NOT NULL)''',
  '''CREATE TABLE purchases (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    supplier_id INTEGER NOT NULL REFERENCES suppliers(id), location_id INTEGER NOT NULL REFERENCES locations(id),
    purchase_number TEXT NOT NULL, invoice_number TEXT, purchase_date TEXT NOT NULL,
    subtotal NUMERIC NOT NULL DEFAULT 0, tax_amount NUMERIC NOT NULL DEFAULT 0,
    discount_amount NUMERIC NOT NULL DEFAULT 0, total_amount NUMERIC NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'DRAFT', notes TEXT, created_by INTEGER NOT NULL REFERENCES users(id),
    created_at TEXT NOT NULL, UNIQUE(business_id, purchase_number))''',
  '''CREATE TABLE purchase_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_id INTEGER NOT NULL REFERENCES purchases(id),
    product_id INTEGER NOT NULL REFERENCES products(id), quantity_ordered NUMERIC NOT NULL,
    quantity_received NUMERIC NOT NULL DEFAULT 0, unit_cost NUMERIC NOT NULL,
    tax_rate NUMERIC NOT NULL DEFAULT 0, discount_amount NUMERIC NOT NULL DEFAULT 0,
    line_total NUMERIC NOT NULL DEFAULT 0)''',
  '''CREATE TABLE purchase_receipts (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    purchase_id INTEGER NOT NULL REFERENCES purchases(id), receipt_number TEXT NOT NULL,
    received_at TEXT NOT NULL, received_by INTEGER NOT NULL REFERENCES users(id), notes TEXT,
    created_at TEXT NOT NULL, UNIQUE(business_id, receipt_number))''',
  '''CREATE TABLE purchase_receipt_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT, purchase_receipt_id INTEGER NOT NULL REFERENCES purchase_receipts(id),
    purchase_item_id INTEGER NOT NULL REFERENCES purchase_items(id), product_id INTEGER NOT NULL REFERENCES products(id),
    quantity_received NUMERIC NOT NULL, unit_cost NUMERIC NOT NULL)''',
  '''CREATE TABLE sales (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    location_id INTEGER NOT NULL REFERENCES locations(id), sale_number TEXT NOT NULL,
    customer_name TEXT, customer_phone TEXT, subtotal NUMERIC NOT NULL DEFAULT 0,
    tax_amount NUMERIC NOT NULL DEFAULT 0, discount_amount NUMERIC NOT NULL DEFAULT 0,
    total_amount NUMERIC NOT NULL DEFAULT 0, status TEXT NOT NULL DEFAULT 'DRAFT',
    sold_by INTEGER NOT NULL REFERENCES users(id), completed_at TEXT, created_at TEXT NOT NULL,
    UNIQUE(business_id, sale_number))''',
  '''CREATE TABLE sale_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL REFERENCES sales(id),
    product_id INTEGER NOT NULL REFERENCES products(id), quantity NUMERIC NOT NULL,
    unit_price NUMERIC NOT NULL, unit_cost NUMERIC NOT NULL, tax_rate NUMERIC NOT NULL DEFAULT 0,
    discount_amount NUMERIC NOT NULL DEFAULT 0, line_total NUMERIC NOT NULL)''',
  '''CREATE TABLE sale_payments (
    id INTEGER PRIMARY KEY AUTOINCREMENT, sale_id INTEGER NOT NULL REFERENCES sales(id),
    payment_method TEXT NOT NULL, amount NUMERIC NOT NULL, reference TEXT,
    payment_status TEXT NOT NULL DEFAULT 'PENDING', paid_at TEXT)''',
  '''CREATE TABLE notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    user_id INTEGER NOT NULL REFERENCES users(id), title TEXT NOT NULL, message TEXT NOT NULL,
    notification_type TEXT NOT NULL, reference_type TEXT, reference_id INTEGER, read_at TEXT, created_at TEXT NOT NULL)''',
  '''CREATE TABLE user_notification_preferences (
    id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL REFERENCES users(id),
    business_id INTEGER NOT NULL REFERENCES businesses(id), notification_type TEXT NOT NULL,
    in_app_enabled INTEGER NOT NULL DEFAULT 1, push_enabled INTEGER NOT NULL DEFAULT 1,
    UNIQUE(user_id, business_id, notification_type))''',
  '''CREATE TABLE audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT, business_id INTEGER NOT NULL REFERENCES businesses(id),
    user_id INTEGER REFERENCES users(id), action TEXT NOT NULL, entity_type TEXT NOT NULL,
    entity_id INTEGER NOT NULL, old_values TEXT, new_values TEXT, ip_address TEXT, created_at TEXT NOT NULL)''',
  '''CREATE TABLE refresh_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL REFERENCES users(id),
    token_hash TEXT NOT NULL, expires_at TEXT NOT NULL, revoked_at TEXT, created_at TEXT NOT NULL)''',
  '''CREATE TABLE password_reset_tokens (
    id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL REFERENCES users(id),
    token_hash TEXT NOT NULL, expires_at TEXT NOT NULL, used_at TEXT, created_at TEXT NOT NULL)''',
  'CREATE INDEX idx_products_business ON products(business_id)',
  'CREATE INDEX idx_stock_movements_lookup ON stock_movements(business_id, product_id, location_id, created_at)',
  'CREATE INDEX idx_sales_business_date ON sales(business_id, created_at)',
  'CREATE INDEX idx_purchases_business_date ON purchases(business_id, purchase_date)',
];
