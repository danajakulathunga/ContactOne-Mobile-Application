import 'dart:io';

class Contact {
  //Database key
  late int id; // late because it will be set when inserting into the database

  String name;
  String email;
  String phoneNumber;
  bool isFavorite;
  String? notes;
  File? imageFile;

  // Constructor
  //required named parameters
  Contact({
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.isFavorite = false,
    this.notes,
    this.imageFile,
  });

  // Convert a map to a Contact object
  Map<String, dynamic> toMap() {
    // Convert Contact object to a map for easier storage or transmission
    return {
      // Lowercased name to support case-insensitive DB sorting when needed
      'nameLower': name.toLowerCase(),
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      //isFavorite is stored as an integer (1 for true, 0 for false)
      'isFavorite': isFavorite ? 1 : 0,
      'notes': notes,
      // Store the image file path if imageFile is not null
      'imageFilePath': imageFile?.path,
    };
  }

  static Contact fromMap(Map<String, dynamic> map) {
    // Create a Contact object from a map
    return Contact(
      name: map['name'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      isFavorite: map['isFavorite'] == 1 ? true : false,
      notes: map['notes'],
      imageFile: map['imageFilePath'] != null
          ? File(map['imageFilePath'])
          : null,
    );
  }
}
