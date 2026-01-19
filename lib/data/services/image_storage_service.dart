import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Service for managing persistent storage of contact profile images.
///
/// Handles copying images from temporary cache/gallery locations to a
/// permanent app-specific storage directory, preventing them from being
/// deleted by the system's cache cleanup.
class ImageStorageService {
  static const String _contactImagesDir = 'contact_images';

  /// Saves a contact profile image to persistent storage.
  ///
  /// Takes an image file from a temporary location (e.g., cache, gallery, or camera)
  /// and copies it to the app's documents directory with a stable filename.
  ///
  /// Parameters:
  ///   - [imageFile]: The temporary image file to save
  ///   - [contactId]: Optional. Unique contact identifier. If provided, will be part of filename.
  ///
  /// Returns: A [File] object pointing to the permanently stored image, or null if save failed.
  ///
  /// Throws: May throw exceptions related to file I/O or directory access.
  static Future<File?> saveContactImage(
    File imageFile, {
    int? contactId,
  }) async {
    try {
      // Verify the source file exists
      if (!imageFile.existsSync()) {
        return null;
      }

      // Get the app's documents directory
      final appDocDir = await getApplicationDocumentsDirectory();

      // Create the contact images subdirectory if it doesn't exist
      final contactImagesDirectory = Directory(
        '${appDocDir.path}/$_contactImagesDir',
      );
      if (!contactImagesDirectory.existsSync()) {
        contactImagesDirectory.createSync(recursive: true);
      }

      // Generate a stable filename
      // Use contact ID if available, otherwise use timestamp
      final fileName = _generateStableFilename(contactId);

      // Create the destination file path
      final destinationFile = File(
        '${contactImagesDirectory.path}/$fileName',
      );

      // Copy the image file to the permanent location
      final copiedFile = await imageFile.copy(destinationFile.path);

      return copiedFile;
    } catch (e) {
      return null;
    }
  }

  /// Generates a stable, unique filename for a contact image.
  ///
  /// If [contactId] is provided, creates a filename based on it.
  /// Otherwise, creates a filename based on timestamp for new contacts.
  static String _generateStableFilename(int? contactId) {
    if (contactId != null && contactId > 0) {
      // Use contact ID as filename for consistent naming across saves
      return 'contact_${contactId}_image.jpg';
    }

    // Fallback: use timestamp for new contacts
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'contact_${timestamp}_image.jpg';
  }

  /// Checks if a stored image file still exists at the given path.
  ///
  /// This should be called before attempting to load/display an image
  /// to ensure the file hasn't been deleted by system cleanup.
  static bool imageFileExists(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final file = File(imagePath);
      return file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Deletes a contact's image file from persistent storage.
  ///
  /// Call this when a contact's image is removed or when deleting a contact.
  static Future<bool> deleteContactImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return false;
    }

    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cleans up orphaned image files in the contact images directory.
  ///
  /// Useful for removing images of deleted contacts.
  /// Provide a list of valid image paths that should be kept.
  static Future<int> cleanupOrphanedImages(
    List<String?> validImagePaths,
  ) async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final contactImagesDirectory = Directory(
        '${appDocDir.path}/$_contactImagesDir',
      );

      if (!contactImagesDirectory.existsSync()) {
        return 0;
      }

      int deletedCount = 0;
      final validPaths = validImagePaths
          .whereType<String>()
          .toSet(); // Convert to set for faster lookup

      final files = contactImagesDirectory.listSync();
      for (final entity in files) {
        if (entity is File && !validPaths.contains(entity.path)) {
          try {
            await entity.delete();
            deletedCount++;
          } catch (e) {
            // Continue with next file if deletion fails
          }
        }
      }

      return deletedCount;
    } catch (e) {
      return 0;
    }
  }

  /// Gets the path to the contact images storage directory.
  ///
  /// Useful for debugging or manual inspection of stored images.
  static Future<String> getContactImagesDirPath() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return '${appDocDir.path}/$_contactImagesDir';
  }
}
