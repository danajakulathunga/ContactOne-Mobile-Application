import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:contacts_app/data/services/image_storage_service.dart';

/// A full-screen preview widget for contact profile pictures.
///
/// Displays the profile picture in a fullscreen black background view with the ability to:
/// - View the picture in high quality
/// - Edit (capture from camera or select from gallery)
/// - Delete the picture
/// - Share the picture with other apps
///
/// Mimics WhatsApp's profile picture preview design.
class ProfilePicturePreview extends StatefulWidget {
  final File? imageFile;
  final String contactName;
  final Function(File?) onImageChanged;
  final int? contactId;

  const ProfilePicturePreview({
    super.key,
    required this.imageFile,
    required this.contactName,
    required this.onImageChanged,
    this.contactId,
  });

  @override
  State<ProfilePicturePreview> createState() => _ProfilePicturePreviewState();
}

/// State class managing the profile picture preview interactions
class _ProfilePicturePreviewState extends State<ProfilePicturePreview> {
  /// Instance of ImagePicker for handling image capture and selection
  final ImagePicker _imagePicker = ImagePicker();

  /// Captures a photo from the device camera and updates the profile picture.
  ///
  /// Applies a max width of 600 pixels for optimized file size.
  /// Copies the captured image to persistent storage to prevent deletion
  /// by system cache cleanup.
  /// Closes the preview screen after successful capture.
  Future<void> _pickFromCamera() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
      );
      if (pickedFile != null) {
        // Save the picked image to persistent storage
        final persistedImageFile = await ImageStorageService.saveContactImage(
          File(pickedFile.path),
          contactId: widget.contactId,
        );

        if (persistedImageFile != null) {
          widget.onImageChanged(persistedImageFile);
          if (mounted) Navigator.pop(context);
        } else {
          _showError('Failed to save image to device storage');
        }
      }
    } catch (e) {
      _showError('Failed to capture image');
    }
  }

  /// Selects a photo from the device gallery and updates the profile picture.
  ///
  /// Applies a max width of 600 pixels for optimized file size.
  /// Copies the selected image to persistent storage to prevent deletion
  /// by system cache cleanup.
  /// Closes the preview screen after successful selection.
  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
      );
      if (pickedFile != null) {
        // Save the picked image to persistent storage
        final persistedImageFile = await ImageStorageService.saveContactImage(
          File(pickedFile.path),
          contactId: widget.contactId,
        );

        if (persistedImageFile != null) {
          widget.onImageChanged(persistedImageFile);
          if (mounted) Navigator.pop(context);
        } else {
          _showError('Failed to save image to device storage');
        }
      }
    } catch (e) {
      _showError('Failed to pick image');
    }
  }

  /// Removes the current profile picture by setting it to null.
  ///
  /// Notifies the parent widget through the [onImageChanged] callback
  /// and closes the preview screen.
  Future<void> _deleteImage() async {
    widget.onImageChanged(null);
    if (mounted) Navigator.pop(context);
  }

  /// Shares the profile picture using the system share sheet.
  ///
  /// Includes the contact name in the share text.
  /// Shows an error message if no image is available or sharing fails.
  Future<void> _shareImage() async {
    if (widget.imageFile == null) {
      _showError('No image to share');
      return;
    }

    try {
      await Share.shareXFiles(
        [XFile(widget.imageFile!.path)],
        text: '${widget.contactName}\'s profile picture',
      );
    } catch (e) {
      _showError('Failed to share image');
    }
  }

  /// Displays an error message to the user via a SnackBar.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Displays a modal bottom sheet dialog with image editing options.
  ///
  /// Provides four options:
  /// - Take Photo: Capture a new photo from the camera
  /// - Choose from Gallery: Select an existing image from device storage
  /// - Delete Photo: Remove the current profile picture (only shown if image exists)
  /// - Cancel: Close the dialog without making changes
  ///
  /// Styled with rounded corners and a visual drag handle at the top.
  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Visual drag handle at the top of the bottom sheet
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Option to capture a new photo from the camera
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              // Option to select an image from device gallery
              ListTile(
                leading: const Icon(Icons.image_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              // Option to delete the current profile picture (only shown if image exists)
              if (widget.imageFile != null)
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: const Text('Delete Photo'),
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _deleteImage();
                  },
                ),
              // Option to close the dialog without making changes
              ListTile(
                leading: const Icon(Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the fullscreen profile picture preview interface.
  ///
  /// Features:
  /// - Black background for immersive viewing experience
  /// - Edit button to open the edit dialog with image editing options
  /// - Share button to share the picture via system share sheet
  /// - Displays the image in fit.contain mode or a placeholder if no image exists
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Black AppBar with back, edit, and share buttons
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: Colors.white),
            onPressed: _showEditDialog,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: _shareImage,
            tooltip: 'Share',
          ),
        ],
      ),
      backgroundColor: Colors.black,
      // Display the image in the center with fallback placeholder
      body: Center(
        child: widget.imageFile != null &&
                ImageStorageService.imageFileExists(widget.imageFile!.path)
            ? Image.file(
                widget.imageFile!,
                fit: BoxFit.contain,
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No image available',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
