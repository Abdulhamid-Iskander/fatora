import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'appliance_store.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT,
        manufacturer TEXT,
        price REAL,
        unit_price REAL,
        purchase_date TEXT,
        paid_to_manufacturer REAL,
        quantity INTEGER,
        notes TEXT,
        installments_count INTEGER,
        installment_amount REAL,
        days_between_installments INTEGER,
        next_installment_date TEXT
      )
      ''');

    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        date TEXT,
        customer_name TEXT,
        customer_id_number TEXT,
        customer_phone_number TEXT,
        items TEXT,
        installments_count INTEGER,
        installment_amount REAL,
        days_between_installments INTEGER,
        next_installment_date TEXT,
        paid_amount REAL
      )
      ''');

    await db.execute('''
      CREATE TABLE customer_installments(
        id TEXT PRIMARY KEY,
        invoice_id TEXT,
        customer_name TEXT,
        product_name TEXT,
        installment_number INTEGER,
        amount REAL,
        due_date TEXT,
        paid_date TEXT,
        is_paid INTEGER DEFAULT 0,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id)
      )
      ''');

    await db.execute('''
      CREATE TABLE product_installments(
        id TEXT PRIMARY KEY,
        product_id TEXT,
        product_name TEXT,
        installment_number INTEGER,
        amount REAL,
        due_date TEXT,
        paid_date TEXT,
        is_paid INTEGER DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
      ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // يمكن تركها فارغة الآن لأن onCreate أصبح يحتوي على كل الأعمدة المطلوبة
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    Database db = await database;
    return await db.insert('products', product);
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    Database db = await database;
    return await db.query('products');
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    Database db = await database;
    return await db.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
  }

  Future<int> deleteProduct(String id) async {
    Database db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertInvoice(Map<String, dynamic> invoice) async {
    Database db = await database;
    return await db.insert('invoices', invoice);
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    Database db = await database;
    return await db.query('invoices', orderBy: 'id ASC');
  }

  Future<int> insertCustomerInstallment(
      Map<String, dynamic> installment) async {
    Database db = await database;
    return await db.insert('customer_installments', installment);
  }

  Future<List<Map<String, dynamic>>> getCustomerInstallments() async {
    Database db = await database;
    return await db.query('customer_installments', orderBy: 'due_date ASC');
  }

  Future<int> updateCustomerInstallment(
      Map<String, dynamic> installment) async {
    Database db = await database;
    return await db.update(
      'customer_installments',
      installment,
      where: 'id = ?',
      whereArgs: [installment['id']],
    );
  }

  Future<int> deleteCustomerInstallment(String id) async {
    Database db = await database;
    return await db.delete(
      'customer_installments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markInstallmentAsPaid(
      String installmentId, DateTime paidDate) async {
    Database db = await database;
    return await db.update(
      'customer_installments',
      {
        'is_paid': 1,
        'paid_date': paidDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [installmentId],
    );
  }

  Future<int> insertProductInstallment(Map<String, dynamic> installment) async {
    Database db = await database;
    return await db.insert('product_installments', installment);
  }

  Future<List<Map<String, dynamic>>> getProductInstallments() async {
    Database db = await database;
    return await db.query('product_installments', orderBy: 'due_date ASC');
  }

  Future<int> updateProductInstallment(Map<String, dynamic> installment) async {
    Database db = await database;
    return await db.update(
      'product_installments',
      installment,
      where: 'id = ?',
      whereArgs: [installment['id']],
    );
  }

  Future<int> deleteProductInstallment(String id) async {
    Database db = await database;
    return await db.delete(
      'product_installments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markProductInstallmentAsPaid(
      String installmentId, DateTime paidDate) async {
    Database db = await database;
    return await db.update(
      'product_installments',
      {
        'is_paid': 1,
        'paid_date': paidDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [installmentId],
    );
  }
}
