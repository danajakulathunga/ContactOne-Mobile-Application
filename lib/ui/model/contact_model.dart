import 'package:contacts_app/data/contact.dart';
import 'package:contacts_app/data/db/contact_dao.dart';
import 'package:faker/faker.dart';
import 'package:scoped_model/scoped_model.dart';

class ContactsModel extends Model {
  //Instance of ContactDao to interact with the database
  //Directly in ContactsModel class
  final ContactDao _contactDao = ContactDao();

  // In-memory contacts list
  List<Contact> _contacts = [];

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Getter to access the contacts
  // Returns a sorted list with favorites on top
  List<Contact> get contacts => _contacts;

  // Centralized sorter: favorites first, then name A–Z (case-insensitive)
  void _sortContacts() {
    _contacts.sort((a, b) {
      // Favorites first
      if (a.isFavorite != b.isFavorite) {
        return b.isFavorite ? 1 : -1; // true comes before false
      }
      // Case-insensitive name sort
      final an = a.name.toLowerCase();
      final bn = b.name.toLowerCase();
      return an.compareTo(bn);
    });
  }

  // Method to load contacts from the database
  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    final fetched = await _contactDao.getAllSortedOrder();
    _contacts = fetched;
    _sortContacts();

    _isLoading = false;
    notifyListeners();
  }

  // Method to add a new contact
  Future<void> addContact(Contact contact) async {
    await _contactDao.insert(contact);
    await loadContacts();
  }

  // Method to update an existing contact
  Future<void> updateContact(Contact contact) async {
    await _contactDao.update(contact);
    await loadContacts();
  }

  // Method to delete a contact
  Future<void> deleteContact(Contact contact) async {
    await _contactDao.delete(contact.id);
    await loadContacts();
  }

  // Method to change the favorite status of a contact
  Future<void> changeFavoriteStatus(Contact contact) async {
    contact.isFavorite = !contact.isFavorite;
    await _contactDao.update(contact);
    await loadContacts();
  }
}
