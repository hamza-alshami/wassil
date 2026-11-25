import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Opens and owns the SQLite database used by the orders feature.
///
/// [databasePath] can be provided by tests to isolate their database.
class AppDatabase {
  AppDatabase({this.databasePath});

  final String? databasePath;

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get database {
    final openedDatabase = _database;
    if (openedDatabase != null) return Future.value(openedDatabase);
    return _openingDatabase ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final databasePath =
        this.databasePath ??
        path.join(await getDatabasesPath(), 'wassel_orders.db');
    final database = await openDatabase(
      databasePath,
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE orders (
            order_number TEXT PRIMARY KEY,
            position INTEGER NOT NULL,
            date TEXT,
            total REAL NOT NULL,
            status TEXT NOT NULL,
            customer_name TEXT NOT NULL,
            address TEXT NOT NULL
          )
        ''');
        await database.execute('''
          CREATE TABLE order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_number TEXT NOT NULL,
            position INTEGER NOT NULL,
            name TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            price REAL NOT NULL,
            FOREIGN KEY (order_number) REFERENCES orders(order_number)
              ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE order_timeline (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_number TEXT NOT NULL,
            position INTEGER NOT NULL,
            title TEXT NOT NULL,
            completed INTEGER NOT NULL,
            FOREIGN KEY (order_number) REFERENCES orders(order_number)
              ON DELETE CASCADE
          )
        ''');
        await database.execute('''
          CREATE TABLE sync_metadata (
            id INTEGER PRIMARY KEY CHECK (id = 1),
            saved_at TEXT NOT NULL
          )
        ''');
      },
    );
    _database = database;
    return database;
  }

  /// Closes the current connection. The next access opens it again.
  ///
  /// Waits for any in-progress open to complete before closing so the
  /// database handle is never abandoned in the background.
  Future<void> close() async {
    final pendingOpen = _openingDatabase;
    final alreadyOpen = _database;
    _database = null;
    _openingDatabase = null;

    // If an open was in flight, wait for it then close the resulting handle.
    if (pendingOpen != null) {
      final db = await pendingOpen.catchError((_) => null as Database?);
      await db?.close();
    } else {
      await alreadyOpen?.close();
    }
  }
}
