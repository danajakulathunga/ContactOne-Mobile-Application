import '../contact.dart';
import 'app_database.dart';
import 'package:sembast/sembast.dart';

// Data Access Object (DAO) for managing contacts in the Sembast database

class ContactDao {
  static const String CONTACT_STORE_NAME = 'contacts'; // Name of the store

  // Store reference
  // Using an integer key for each contact
  // 'contacts' is the name of the store
  final _contactStore = intMapStoreFactory.store(CONTACT_STORE_NAME);

  Future<Database> get _db async =>
      await AppDatabase.instance.database; // Get the database instance

  //Get all contacts from the database
  //CRUD operations

  // Insert a new contact into the database
  Future insert(Contact contact) async {
    await _contactStore.add(await _db, contact.toMap());
  }

  // Update an existing contact in the database
  Future update(Contact contact) async {
    final finder = Finder(filter: Filter.byKey(contact.id));
    await _contactStore.update(await _db, contact.toMap(), finder: finder);
  }

  // Delete a contact from the database
  Future delete(int id) async {
    final finder = Finder(filter: Filter.byKey(id));
    await _contactStore.delete(await _db, finder: finder);
  }

  // Retrieve all contacts from the database
  Future<List<Contact>> getAllSortedOrder() async {
    // Define a finder to sort contacts by name in ascending order
    // Use case-insensitive name sorting via precomputed 'nameLower'
    final finder = Finder(
      sortOrders: [
        SortOrder('isFavorite', false), // Favorites first (1 before 0)
        SortOrder(
          'nameLower',
        ), // Then by name alphabetically (case-insensitive)
      ],
    );

    final recordSnapshots = await _contactStore.find(await _db, finder: finder);

    // Convert the snapshots to Contact objects
    // and assign the database key to each contact
    return recordSnapshots.map((snapshot) {
      final contact = Contact.fromMap(snapshot.value);
      contact.id = snapshot.key; // Assign the database key to the contact
      return contact;
    }).toList();
  }
}
