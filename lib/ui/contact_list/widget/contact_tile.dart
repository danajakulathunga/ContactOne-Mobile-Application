import 'package:contacts_app/data/contact.dart';
import 'package:contacts_app/data/services/image_storage_service.dart';
import 'package:contacts_app/ui/contact/contact_edit_page.dart';
import 'package:contacts_app/ui/model/contact_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

// Comprehensive email format validator supporting various domain types
// Validates: local part, @ symbol, domain, and TLD (including country codes)
// Examples: user@example.com, john.doe@company.co.uk, test+tag@gmail.com
final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  caseSensitive: false,
);

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

// Format phone number with spaces
String _formatPhoneNumber(String phoneNumber) {
  // Remove all non-digit characters except +
  final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

  if (cleaned.isEmpty) return phoneNumber;

  // If it starts with +94, handle international format (+94 000 000 000)
  if (cleaned.startsWith('+94')) {
    final countryCode = '+94';
    final remainingDigits = cleaned.substring(3);

    // Format as groups of 3 digits
    final parts = <String>[];
    for (int i = 0; i < remainingDigits.length; i += 3) {
      final end =
          (i + 3 <= remainingDigits.length) ? i + 3 : remainingDigits.length;
      parts.add(remainingDigits.substring(i, end));
    }

    return '$countryCode ${parts.join(' ')}';
  }

  // For local numbers starting with 0, format as (070 0000 000)
  if (cleaned.startsWith('0')) {
    // Format as 3-4-3 digit groups
    if (cleaned.length >= 3) {
      final part1 = cleaned.substring(0, 3); // 3 digits
      final remaining = cleaned.substring(3);

      if (remaining.length >= 4) {
        final part2 = remaining.substring(0, 4); // 4 digits
        final part3 = remaining.substring(4); // remaining digits
        return '$part1 $part2 $part3';
      } else {
        return '$part1 $remaining';
      }
    }
  }

  // Fallback: For other numbers, format in groups of 3
  final parts = <String>[];
  for (int i = 0; i < cleaned.length; i += 3) {
    final end = (i + 3 <= cleaned.length) ? i + 3 : cleaned.length;
    parts.add(cleaned.substring(i, end));
  }

  return parts.join(' ');
}

class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contactIndex,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final int contactIndex;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    // Access the ContactsModel to get the contact details
    // and favorite status
    // for the contact at contactIndex
    final model = ScopedModel.of<ContactsModel>(context);
    final displayedContact = model.contacts[contactIndex];

    // In selection mode, show simpler tile with checkbox
    if (isSelectionMode) {
      return _buildSelectionTile(context, displayedContact);
    }

    return Slidable(
      // Slide to delete action
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        // Email, Share, and Delete actions
        children: [
          SlidableAction(
            label: 'Email',
            backgroundColor: Colors.blue,
            icon: Icons.mail,
            onPressed: (context) => _sendEmail(context, displayedContact.email),
          ),
          SlidableAction(
            label: 'Share',
            backgroundColor: Colors.teal,
            icon: Icons.share_rounded,
            onPressed: (context) => _shareContact(context, displayedContact),
          ),
          SlidableAction(
            label: 'Delete',
            backgroundColor: Colors.red,
            icon: Icons.delete,
            onPressed: (context) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Contact'),
                  content: const Text(
                    'Are you sure you want to delete this contact?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await model.deleteContact(displayedContact);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact deleted')),
                );
              }
            },
          ),
        ],
      ),

      child: _buildContent(context, displayedContact, model),
    );
  }

  Future _callPhoneNUmber(BuildContext context, String phoneNumber) async {
    // Implement phone call functionality here
    final url = 'tel:$phoneNumber';
    // Use url_launcher or similar package to launch the URL
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot make a call to $url'),
        ), // Show error message
      );
    }
  }

  Future _sendEmail(BuildContext context, String emailAddress) async {
    // Trim whitespace from email address
    final trimmedEmail = emailAddress.trim();

    // Validate that email address exists
    if (trimmedEmail.isEmpty) {
      _showSnack(
        context,
        'No email address found for this contact',
      );
      return;
    }

    // Validate email format using comprehensive regex
    // Ensures proper format: name@domain.ext
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      _showSnack(
        context,
        'Invalid email address format. Please update the contact.',
      );
      return;
    }

    // Create mailto URI with proper encoding
    // This ensures the email domain is correctly included (e.g., @gmail.com, @outlook.com)
    // The "To" field will be prefilled with the contact's email address
    final emailUri = Uri(
      scheme: 'mailto',
      path: trimmedEmail,
    );

    try {
      // Attempt to launch email client directly
      // NOTE: We try to launch first rather than checking canLaunchUrl()
      // because canLaunchUrl() can return false even when email apps exist on some devices

      // Primary method: Launch with external application mode
      // This opens the default email app (Gmail, Outlook, Apple Mail, etc.)
      bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      // Fallback 1: Try platform default mode
      // This may show an app chooser dialog on Android if multiple email apps exist
      if (!launched) {
        launched = await launchUrl(
          emailUri,
          mode: LaunchMode.platformDefault,
        );
      }

      // Fallback 2: Use string-based launcher with external application
      // Handles edge cases on certain Android OEM ROMs where Uri-based launching fails
      if (!launched) {
        launched = await launchUrlString(
          'mailto:$trimmedEmail',
          mode: LaunchMode.externalApplication,
        );
      }

      // Fallback 3: Final attempt with string-based platform default
      if (!launched) {
        launched = await launchUrlString(
          'mailto:$trimmedEmail',
          mode: LaunchMode.platformDefault,
        );
      }

      // If all launch methods return false, show error
      // This is rare but can happen on some platforms
      if (!launched) {
        _showSnack(
          context,
          'No email client found on this device. Please install one to send emails.',
        );
      }
      // Success: Email client opened with:
      // - "To" field prefilled with the contact's email
      // - Subject and body fields empty for user customization
    } on PlatformException catch (e) {
      // Handle platform-specific errors
      // Common error codes:
      // - 'ACTIVITY_NOT_FOUND' on Android when no email app handles mailto:
      // - 'launch_error' on iOS when no mail app is configured
      if (e.code == 'ACTIVITY_NOT_FOUND' || e.code == 'launch_error') {
        _showSnack(
          context,
          'No email client found on this device. Please install one to send emails.',
        );
      } else {
        // Other platform errors
        _showSnack(
          context,
          'Unable to open email client. Please try again.',
        );
      }
    } catch (e) {
      // Handle any other unexpected errors
      // This catches network issues, permission problems, etc.
      _showSnack(
        context,
        'Failed to open email client. Please try again.',
      );
    }
  }

  Future _sendSms(BuildContext context, String phoneNumber) async {
    // Normalize phone number (remove spaces, dashes, parentheses)
    final cleanPhone = phoneNumber.replaceAll(RegExp(r"[^\d+]"), "");

    // Messaging apps to check
    final messagingApps = [
      {
        'name': 'SMS',
        'icon': Icons.sms_rounded,
        'checkScheme': 'sms:$phoneNumber',
        'launchScheme': 'sms:$phoneNumber',
      },
      {
        'name': 'WhatsApp',
        'icon': Icons.chat_rounded,
        'checkScheme': 'whatsapp://send?phone=$cleanPhone',
        'launchScheme': 'https://wa.me/$cleanPhone',
      },
      {
        'name': 'Telegram',
        'icon': Icons.send_rounded,
        'checkScheme': 'tg://resolve?phone=$cleanPhone',
        'launchScheme': 'tg://resolve?phone=$cleanPhone',
      },
    ];

    // Check which apps are available
    final availableApps = <Map<String, dynamic>>[];

    for (final app in messagingApps) {
      try {
        final uri = Uri.parse(app['checkScheme'] as String);
        final isInstalled = await canLaunchUrl(uri);
        if (isInstalled) {
          availableApps.add(app);
        }
      } catch (e) {
        // Skip apps that cause errors during check
        continue;
      }
    }

    if (availableApps.isEmpty) {
      _showSnack(context, 'No messaging app available');
      return;
    }

    if (availableApps.length == 1) {
      // Only one app available, launch directly
      await _launchMessagingApp(availableApps[0], phoneNumber);
      return;
    }

    // Show dialog with available messaging apps
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Message'),
        content: const Text('Choose a messaging app:'),
        actions: [
          ...availableApps.map((app) {
            return TextButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _launchMessagingApp(app, phoneNumber);
              },
              icon: Icon(app['icon'] as IconData),
              label: Text(app['name'] as String),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _launchMessagingApp(
    Map<String, dynamic> app,
    String phoneNumber,
  ) async {
    try {
      final launchScheme = app['launchScheme'] as String;
      final uri = Uri.parse(launchScheme);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack(null, '${app['name']} is not installed');
      }
    } catch (e) {
      _showSnack(null, 'Failed to open ${app['name']}');
    }
  }

  Future _shareContact(BuildContext context, Contact contact) async {
    // Build formatted contact details
    final StringBuffer shareText = StringBuffer();

    // Add contact name
    shareText.writeln('📇 Name: ${contact.name}');
    shareText.writeln('');

    // Add phone number
    if (contact.phoneNumber.isNotEmpty) {
      shareText.writeln('📱 Contact Number: ${contact.phoneNumber}');
    }

    // Add email
    if (contact.email.isNotEmpty) {
      shareText.writeln('📧 Email: ${contact.email}');
    }

    // Add notes if available
    if (contact.notes != null && contact.notes!.isNotEmpty) {
      shareText.writeln('📝 Notes: ${contact.notes}');
    }

    try {
      await Share.share(
        shareText.toString(),
        subject: 'Contact: ${contact.name}',
      );
    } catch (e) {
      _showSnack(context, 'Failed to share contact');
    }
  }

  void _showSnack(BuildContext? context, String message) {
    if (context == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Contact displayedContact,
    ContactsModel model,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: theme.cardColor,
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ContactEditPage(editedContact: displayedContact),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildCircleAvatar(displayedContact),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayedContact.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPhoneNumber(displayedContact.phoneNumber),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(
                                0.7,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Call and Message buttons in top-right corner
                Positioned(
                  top: 0,
                  right: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionIcon(
                        icon: Icons.phone_rounded,
                        tooltip: 'Call',
                        onTap: () => _callPhoneNUmber(
                          context,
                          displayedContact.phoneNumber,
                        ),
                        color: Colors.green,
                      ),
                      const SizedBox(width: 14),
                      _ActionIcon(
                        icon: Icons.sms_rounded,
                        tooltip: 'Message',
                        onTap: () =>
                            _sendSms(context, displayedContact.phoneNumber),
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Hero _buildCircleAvatar(Contact displayedContact) {
    return Hero(
      tag: displayedContact.hashCode,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _getAvatarColor(displayedContact.name),
            child: _buildCircleAvatarContent(displayedContact),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAvatarContent(Contact displayedContact) {
    // Check if image file exists before attempting to display it
    final hasValidImage = displayedContact.imageFile != null &&
        ImageStorageService.imageFileExists(displayedContact.imageFile!.path);

    if (!hasValidImage) {
      return Center(
        child: Text(
          displayedContact.name.isNotEmpty
              ? displayedContact.name[0].toUpperCase()
              : '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 22,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return ClipOval(
        child: AspectRatio(
          aspectRatio: 1,
          child: Image.file(displayedContact.imageFile!, fit: BoxFit.cover),
        ),
      );
    }
  }

  Widget _buildSelectionTile(BuildContext context, Contact displayedContact) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.cardColor,
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            onSelectionChanged?.call(!isSelected);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    onSelectionChanged?.call(value ?? false);
                  },
                ),
                const SizedBox(width: 8),
                _buildCircleAvatar(displayedContact),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        displayedContact.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayedContact.phoneNumber,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final widgetIcon = Icon(
      icon,
      size: 22,
      color: color ?? Theme.of(context).iconTheme.color,
    );
    return Tooltip(
      message: tooltip ?? '',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: widgetIcon,
        ),
      ),
    );
  }
}
