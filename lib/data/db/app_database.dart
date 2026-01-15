import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path/path.dart';

// lib/data/db/app_database.dart
// Database setup and initialization for the contacts app

class AppDatabase {
  // Singleton instance
  static final AppDatabase _singleton = AppDatabase._();

  // Getter for the singleton instance
  static AppDatabase get instance => _singleton;

  // Completer to manage database opening
  late Completer<Database> _dbOpenCompleter;

  // Singleton instance
  // Private constructor
  // Ensures only one instance of AppDatabase exists
  AppDatabase._() {
    _dbOpenCompleter = Completer();
  }

  Future<Database> get database async {
    if (!_dbOpenCompleter.isCompleted) {
      // Start opening the database
      _openDatabase();
    }

    // Await the database opening
    // and return it
    return _dbOpenCompleter.future;
  }

  Future _openDatabase() async {
    // Initialize the database if it hasn't been initialized yet
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    // Create the database path
    final dbPath = join(appDocumentsDir.path, 'contacts.db');
    // Open the database
    final database = await databaseFactoryIo.openDatabase(dbPath);
    _dbOpenCompleter.complete(database);
  }
}
