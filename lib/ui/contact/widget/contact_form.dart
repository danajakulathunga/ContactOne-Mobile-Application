import 'dart:io';
import 'package:contacts_app/data/contact.dart';
import 'package:contacts_app/data/services/image_storage_service.dart';
import 'package:contacts_app/ui/model/contact_model.dart';
import 'package:contacts_app/ui/contact/widget/profile_picture_preview.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:image_picker/image_picker.dart';

// Generate consistent color based on first letter
Color _getAvatarColor(String name) {
  if (name.isEmpty) return const Color(0xFF4F46E5);
  final letter = name[0].toUpperCase();
  final colors = [
    const Color(0xFFEF4444), // Red
    const Color(0xFFF97316), // Orange
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEAB308), // Yellow
    const Color(0xFF84CC16), // Lime
    const Color(0xFF22C55E), // Green
    const Color(0xFF10B981), // Emerald
    const Color(0xFF14B8A6), // Teal
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF0EA5E9), // Sky
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF6366F1), // Indigo
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFA855F7), // Purple
    const Color(0xFFD946EF), // Fuchsia
    const Color(0xFFEC4899), // Pink
    const Color(0xFFF43F5E), // Rose
  ];
  final index = (letter.codeUnitAt(0) - 65) % colors.length;
  return colors[index >= 0 ? index : 0];
}

class ContactForm extends StatefulWidget {
  final Contact? editedContact;

  const ContactForm({super.key, this.editedContact});

  @override
  _ContactFormState createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _phoneNumber;
  String? _notes;
  File? _contactImageFile;
  bool _isSubmitting = false;

  bool get isEditMode => widget.editedContact != null;
  bool get hasSelectedCustomImage =>
      _contactImageFile != null &&
      ImageStorageService.imageFileExists(_contactImageFile!.path);

  @override
  void initState() {
    super.initState();
    _contactImageFile = widget.editedContact?.imageFile;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Text(isEditMode ? 'Edit Contact' : 'Create Contact'),
        actions: [
          // Favorite button (Star icon)
          IconButton(
            icon: Icon(
              widget.editedContact?.isFavorite == true
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: widget.editedContact?.isFavorite == true
                  ? Colors.amber
                  : null,
            ),
            onPressed: isEditMode
                ? () async {
                    if (widget.editedContact != null) {
                      final newContact = Contact(
                        name: widget.editedContact!.name,
                        email: widget.editedContact!.email,
                        phoneNumber: widget.editedContact!.phoneNumber,
                        isFavorite: !widget.editedContact!.isFavorite,
                        notes: widget.editedContact!.notes,
                        imageFile: widget.editedContact!.imageFile,
                      );
                      newContact.id = widget.editedContact!.id;
                      await ScopedModel.of<ContactsModel>(context)
                          .updateContact(newContact);
                      setState(() {
                        widget.editedContact?.isFavorite =
                            !widget.editedContact!.isFavorite;
                      });
                    }
                  }
                : null,
            tooltip: 'Favorite',
          ),
          // Save button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: _isSubmitting
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _onSaveContactButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007E9D),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(10),
          children: [
            const SizedBox(height: 16),
            _buildContactPicture(context),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Name',
                      hint: 'Your Name',
                      icon: Icons.person_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Name is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Enter at least 2 characters';
                        }
                        return null;
                      },
                      onSaved: (value) => _name = value?.trim(),
                      initialValue: widget.editedContact?.name,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Contact Number',
                      hint: '+94 700 000 000',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        if (value.replaceAll(RegExp(r'[^\d]'), '').length <
                            10) {
                          return 'Enter at least 10 digits';
                        }
                        return null;
                      },
                      onSaved: (value) => _phoneNumber = value?.trim(),
                      initialValue: widget.editedContact?.phoneNumber,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Email Address',
                      hint: 'username@example.com',
                      icon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        // Comprehensive email validation matching contact_tile.dart
                        final emailPattern = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          caseSensitive: false,
                        );
                        if (!emailPattern.hasMatch(value)) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      onSaved: (value) => _email = value?.trim(),
                      initialValue: widget.editedContact?.email,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Notes (Optional)',
                      hint: 'Add any notes or remarks...',
                      icon: Icons.notes_rounded,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      maxLines: 3,
                      onSaved: (value) => _notes = value?.trim(),
                      initialValue: widget.editedContact?.notes,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildContactPicture(BuildContext context) {
    final halfScreenDiameter = MediaQuery.of(context).size.width / 2;
    final hasImage = _contactImageFile != null;

    return Column(
      children: [
        GestureDetector(
          onTap: _onContactPictureTapped,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Hero(
                tag: widget.editedContact?.hashCode ?? 0,
                child: Container(
                  width: halfScreenDiameter,
                  height: halfScreenDiameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getAvatarColor(
                      widget.editedContact?.name ?? _name ?? '',
                    ),
                  ),
                  child: ClipOval(
                    child: _buildCircleAvatarContent(halfScreenDiameter),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasImage ? 'Tap to change photo' : 'Tap to upload photo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildCircleAvatarContent(double size) {
    if (isEditMode || hasSelectedCustomImage) {
      return _buildEditModeCircleAvatarContent(size);
    } else {
      // Show first letter for new contact if name is entered
      if (_name != null && _name!.isNotEmpty) {
        return Center(
          child: Text(
            _name![0].toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: size / 2.2,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }
      return Icon(Icons.person_rounded, color: Colors.white, size: size / 1.5);
    }
  }

  Widget _buildEditModeCircleAvatarContent(double size) {
    if (isEditMode) {
      // Check if image file exists before attempting to display it
      final hasValidImage = _contactImageFile != null &&
          ImageStorageService.imageFileExists(_contactImageFile!.path);

      if (hasValidImage) {
        return Image.file(_contactImageFile!, fit: BoxFit.cover);
      }
      return Center(
        child: Text(
          widget.editedContact?.name.isNotEmpty == true
              ? widget.editedContact!.name[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size / 2.2,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      // Check if image file exists before attempting to display it
      final hasValidImage = _contactImageFile != null &&
          ImageStorageService.imageFileExists(_contactImageFile!.path);

      if (hasValidImage) {
        return Image.file(_contactImageFile!, fit: BoxFit.cover);
      }
      // For new contact with selected image
      return Icon(Icons.person_rounded, color: Colors.white, size: size / 1.5);
    }
  }

  void _onContactPictureTapped() async {
    final contactName = widget.editedContact?.name ?? _name ?? 'Contact';
    final contactId = isEditMode ? widget.editedContact?.id : null;

    if (mounted) {
      final updatedImage = await Navigator.of(context).push<File?>(
        MaterialPageRoute(
          builder: (context) => ProfilePicturePreview(
            imageFile: _contactImageFile,
            contactName: contactName,
            contactId: contactId,
            onImageChanged: (newImage) {
              // Update the image in this form
              setState(() => _contactImageFile = newImage);
            },
          ),
        ),
      );

      // Handle if image was changed from preview screen
      if (updatedImage != null) {
        setState(() => _contactImageFile = updatedImage);
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    String? initialValue,
    int? maxLines,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines ?? 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  void _onSaveContactButtonPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      setState(() => _isSubmitting = true);

      final newOrEditedContact = Contact(
        name: _name ?? '',
        email: _email ?? '',
        phoneNumber: _phoneNumber ?? '',
        isFavorite: widget.editedContact?.isFavorite ?? false,
        notes: _notes,
        imageFile: _contactImageFile,
      );

      try {
        if (isEditMode) {
          newOrEditedContact.id = widget.editedContact!.id;
          await ScopedModel.of<ContactsModel>(
            context,
          ).updateContact(newOrEditedContact);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact updated successfully'),
                duration: Duration(milliseconds: 1200),
              ),
            );
          }
        } else {
          await ScopedModel.of<ContactsModel>(
            context,
          ).addContact(newOrEditedContact);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact created successfully'),
                duration: Duration(milliseconds: 1200),
              ),
            );
          }
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }
}
