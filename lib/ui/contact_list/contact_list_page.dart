import 'dart:io';
import 'dart:convert';
import 'package:contacts_app/data/contact.dart';
import 'package:contacts_app/ui/contact/contact_create_page.dart';
import 'package:contacts_app/ui/contact_list/widget/contact_tile.dart';
import 'package:contacts_app/ui/model/contact_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  final TextEditingController _searchController = TextEditingController();
  late final ScrollController _scrollController;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  String _query = '';
  bool _isSelectionMode = false;
  final Set<int> _selectedContactIds = {};

  static const platform =
      MethodChannel('com.example.contacts_app/import_export');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Premium theme colors
    final menuBackgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final menuTextColor =
        isDarkMode ? const Color(0xFFE8E8E8) : const Color(0xFF1A1A1A);
    final menuIconColor =
        isDarkMode ? const Color(0xFFB8B8B8) : const Color(0xFF404040);
    final menuHoverColor =
        isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedContactIds.length} selected'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedContactIds.clear();
                  });
                },
              ),
              actions: [
                ScopedModelDescendant<ContactsModel>(
                  builder: (context, child, model) {
                    final allContactIds =
                        model.contacts.map((c) => c.id).toSet();
                    final allSelected =
                        _selectedContactIds.length == allContactIds.length &&
                            allContactIds.isNotEmpty;

                    return IconButton(
                      icon: Icon(
                        allSelected ? Icons.remove_done : Icons.done_all,
                      ),
                      tooltip: allSelected ? 'Deselect All' : 'Select All',
                      onPressed: () {
                        setState(() {
                          if (allSelected) {
                            _selectedContactIds.clear();
                          } else {
                            _selectedContactIds.addAll(allContactIds);
                          }
                        });
                      },
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: _selectedContactIds.isEmpty
                      ? null
                      : () => _shareSelectedContacts(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _selectedContactIds.isEmpty
                      ? null
                      : () => _deleteSelectedContacts(context),
                ),
              ],
            )
          : AppBar(
              title: const Text('My Contacts'),
              leading: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                elevation: isDarkMode ? 8 : 4,
                shadowColor: isDarkMode
                    ? Colors.black.withOpacity(0.6)
                    : Colors.black.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                ),
                color: menuBackgroundColor,
                offset: const Offset(0, 48),
                onSelected: (value) {
                  if (value == 'import') {
                    _showImportDialog(context);
                  } else if (value == 'export') {
                    _exportContacts(context);
                  } else if (value == 'select') {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedContactIds.clear();
                    });
                  } else if (value == 'find_duplicates') {
                    _findAndShowDuplicates(context);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'select',
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          color: menuIconColor,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Select Contacts',
                          style: TextStyle(
                            color: menuTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_download_rounded,
                          color: menuIconColor,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Import Contacts',
                          style: TextStyle(
                            color: menuTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_upload_rounded,
                          color: menuIconColor,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Export Contacts',
                          style: TextStyle(
                            color: menuTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'find_duplicates',
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.content_copy_rounded,
                          color: menuIconColor,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Find Duplicate Contacts',
                          style: TextStyle(
                            color: menuTextColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      body: PageStorage(
        bucket: _pageStorageBucket,
        child: ScopedModelDescendant<ContactsModel>(
          builder: (context, child, model) {
            if (model.isLoading) {
              return _buildSkeletonLoader(context);
            }

            final contacts = model.contacts;
            final filtered = _query.isEmpty
                ? contacts
                : contacts
                    .where(
                      (c) =>
                          c.name.toLowerCase().contains(_query.toLowerCase()) ||
                          c.phoneNumber.toLowerCase().contains(
                                _query.toLowerCase(),
                              ) ||
                          c.email.toLowerCase().contains(_query.toLowerCase()),
                    )
                    .toList();

            final favorites = filtered.where((c) => c.isFavorite).toList();
            final others = filtered.where((c) => !c.isFavorite).toList();

            return CustomScrollView(
              key: const PageStorageKey('contact-list-scroll'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(child: _buildSearchBar(context)),
                if (favorites.isNotEmpty)
                  _buildSectionHeader('Favorites (${favorites.length})'),
                if (favorites.isNotEmpty)
                  _buildContactsSliverList(model, favorites),
                if (favorites.isNotEmpty && others.isNotEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                _buildSectionHeader('All Contacts (${others.length})'),
                _buildContactsSliverList(model, others),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0891B2),
        child: const Icon(
          Icons.person_add,
          size: 32,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ContactCreatePage()),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search contacts',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => _searchController.clear(),
                )
              : null,
        ),
      ),
    );
  }

  SliverPersistentHeader _buildSectionHeader(String title) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SectionHeaderDelegate(
        minHeight: 36,
        maxHeight: 44,
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  SliverList _buildContactsSliverList(ContactsModel model, List contacts) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, i) {
        // We need to map index for ContactTile to model.contacts index.
        final contact = contacts[i];
        final modelIndex = model.contacts.indexOf(contact);
        return ContactTile(
          contactIndex: modelIndex,
          isSelectionMode: _isSelectionMode,
          isSelected: _selectedContactIds.contains(contact.id),
          onSelectionChanged: (selected) {
            setState(() {
              if (selected) {
                _selectedContactIds.add(contact.id);
              } else {
                _selectedContactIds.remove(contact.id);
              }
            });
          },
        );
      }, childCount: contacts.length),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.contact_page_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No contacts found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or add a new contact.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ContactCreatePage(),
                  ),
                );
              },
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add New Contact'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 76,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show import dialog with submenu options
  Future<void> _showImportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Contacts'),
        content: const Text('Choose an import source:'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _importFromContactsApp(context);
            },
            icon: const Icon(Icons.contacts_rounded),
            label: const Text('From Contacts App'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _importFromCSV(context);
            },
            icon: const Icon(Icons.file_download_rounded),
            label: const Text('From CSV File'),
          ),
        ],
      ),
    );
  }

  /// Import contacts from device's contact apps
  Future<void> _importFromContactsApp(BuildContext context) async {
    try {
      // Request READ_CONTACTS permission
      final permissionStatus = await Permission.contacts.request();

      if (permissionStatus.isDenied) {
        if (mounted) {
          _showMessage(context, 'Permission to read contacts was denied');
        }
        return;
      }

      if (permissionStatus.isPermanentlyDenied) {
        if (mounted) {
          _showMessage(
            context,
            'Permission to read contacts is permanently denied. Please enable it in app settings.',
          );
        }
        openAppSettings();
        return;
      }

      // Call native Android method to pick contacts
      try {
        final result = await platform.invokeMethod('pickContacts');

        if (result == null) {
          return;
        }

        final model =
            ScopedModel.of<ContactsModel>(context, rebuildOnChange: false);

        int importedCount = 0;
        int skippedCount = 0;

        // Handle multiple contacts (result is a List)
        final List<dynamic> contactsList = result is List ? result : [result];

        for (final contactData in contactsList) {
          final contactMap = contactData as Map;

          // Parse the contact result
          final name = contactMap['name']?.toString().trim() ?? '';
          final phoneNumber =
              contactMap['phoneNumber']?.toString().trim() ?? '';
          final email = contactMap['email']?.toString().trim() ?? '';

          if (name.isEmpty || phoneNumber.isEmpty) {
            skippedCount++;
            continue;
          }

          // Check for duplicates by phone number
          final normalizedNewPhone =
              phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
          final isDuplicate = model.contacts.any(
            (c) =>
                c.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '') ==
                normalizedNewPhone,
          );

          if (isDuplicate) {
            skippedCount++;
            continue;
          }

          // Create and add the contact
          final contact = Contact(
            name: name,
            phoneNumber: phoneNumber,
            email: email.isNotEmpty ? email : '',
            isFavorite: false,
          );

          await model.addContact(contact);
          importedCount++;
        }

        if (mounted) {
          if (importedCount > 0) {
            final message = importedCount == 1
                ? '1 contact imported successfully'
                : '$importedCount contacts imported successfully';
            final skippedMessage = skippedCount > 0
                ? ' ($skippedCount skipped: duplicates/invalid)'
                : '';
            _showMessage(context, message + skippedMessage);
          } else if (skippedCount > 0) {
            _showMessage(
              context,
              'No contacts imported. $skippedCount skipped (duplicates/invalid)',
            );
          }
        }
      } on PlatformException catch (e) {
        if (mounted) {
          _showMessage(context, 'Import failed: ${e.message}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(context, 'Import failed: ${e.toString()}');
      }
    }
  }

  /// Import contacts from a CSV file
  Future<void> _importFromCSV(BuildContext context) async {
    try {
      // Pick a CSV file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      if (csvData.isEmpty || csvData.length < 2) {
        if (mounted) {
          _showMessage(context, 'Error: Empty or invalid CSV file');
        }
        return;
      }

      // Skip header row (first row)
      final contactsData = csvData.skip(1);
      final model =
          ScopedModel.of<ContactsModel>(context, rebuildOnChange: false);

      int importedCount = 0;
      int skippedCount = 0;

      for (final row in contactsData) {
        if (row.length < 3) {
          skippedCount++;
          continue; // Skip invalid rows
        }

        final name = row[0].toString().trim();
        final phoneNumber = row[1].toString().trim();
        final email = row[2].toString().trim();
        final isFavorite = row.length > 3 ? row[3].toString() == '1' : false;
        final notes = row.length > 4 ? row[4].toString().trim() : '';

        if (name.isEmpty || phoneNumber.isEmpty) {
          skippedCount++;
          continue;
        }

        // Check for duplicates by phone number
        final normalizedNewPhone =
            phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        final isDuplicate = model.contacts.any(
          (c) =>
              c.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '') ==
              normalizedNewPhone,
        );

        if (isDuplicate) {
          skippedCount++;
          continue;
        }

        // Create and add the contact
        final contact = Contact(
          name: name,
          phoneNumber: phoneNumber,
          email: email,
          isFavorite: isFavorite,
          notes: notes.isNotEmpty ? notes : null,
        );

        await model.addContact(contact);
        importedCount++;
      }

      if (mounted) {
        final message = importedCount == 1
            ? '1 contact imported successfully'
            : '$importedCount contacts imported successfully';
        final skippedMessage = skippedCount > 0
            ? ' ($skippedCount skipped: duplicates/invalid)'
            : '';
        _showMessage(context, message + skippedMessage);
      }
    } catch (e) {
      if (mounted) {
        _showMessage(context, 'CSV import failed: ${e.toString()}');
      }
    }
  }

  /// Export all contacts using Storage Access Framework (SAF)
  Future<void> _exportContacts(BuildContext context) async {
    try {
      final model =
          ScopedModel.of<ContactsModel>(context, rebuildOnChange: false);

      if (model.contacts.isEmpty) {
        _showMessage(context, 'No contacts to export');
        return;
      }

      // Prepare CSV data
      final List<List<dynamic>> csvData = [
        ['Name', 'Phone Number', 'Email', 'Is Favorite', 'Notes'],
      ];

      for (final contact in model.contacts) {
        csvData.add([
          contact.name,
          contact.phoneNumber,
          contact.email,
          contact.isFavorite ? '1' : '0',
          contact.notes ?? '',
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'contacts_export_$timestamp.csv';

      // Request storage permission for Android 11+
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        // Try standard storage permission for older Android versions
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (mounted) {
            _showMessage(context, 'Storage permission denied');
          }
          return;
        }
      }

      // Call native Android method to open SAF for export
      try {
        final result = await platform.invokeMethod<String>(
          'exportWithSAF',
          {
            'csvContent': csvString,
            'fileName': fileName,
          },
        );

        if (result != null) {
          if (mounted) {
            _showMessage(
              context,
              'Exported ${model.contacts.length} contacts successfully',
            );
          }
        }
      } on PlatformException catch (e) {
        if (e.code != 'CANCELLED') {
          if (mounted) {
            _showMessage(context, 'Export failed: ${e.message}');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(context, 'Export failed: ${e.toString()}');
      }
    }
  }

  /// Find and show duplicate contacts
  Future<void> _findAndShowDuplicates(BuildContext context) async {
    final model =
        ScopedModel.of<ContactsModel>(context, rebuildOnChange: false);
    final contacts = model.contacts;

    if (contacts.isEmpty) {
      _showMessage(context, 'No contacts to check for duplicates');
      return;
    }

    // Find duplicates based on phone number, name, or email
    final Map<String, List<Contact>> duplicateGroups = {};

    for (int i = 0; i < contacts.length; i++) {
      final contact1 = contacts[i];

      // Normalize data for comparison
      final phone1 =
          contact1.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '').toLowerCase();
      final name1 = contact1.name.trim().toLowerCase();
      final email1 = contact1.email.trim().toLowerCase();

      for (int j = i + 1; j < contacts.length; j++) {
        final contact2 = contacts[j];

        // Normalize data for comparison
        final phone2 = contact2.phoneNumber
            .replaceAll(RegExp(r'[^\d+]'), '')
            .toLowerCase();
        final name2 = contact2.name.trim().toLowerCase();
        final email2 = contact2.email.trim().toLowerCase();

        // Check if contacts are duplicates
        bool isDuplicate = false;
        String duplicateKey = '';

        if (phone1.isNotEmpty && phone1 == phone2) {
          isDuplicate = true;
          duplicateKey = 'phone:$phone1';
        } else if (name1.isNotEmpty &&
            name1 == name2 &&
            email1.isNotEmpty &&
            email1 == email2) {
          isDuplicate = true;
          duplicateKey = 'name-email:$name1-$email1';
        }

        if (isDuplicate) {
          if (!duplicateGroups.containsKey(duplicateKey)) {
            duplicateGroups[duplicateKey] = [contact1];
          }
          if (!duplicateGroups[duplicateKey]!.contains(contact2)) {
            duplicateGroups[duplicateKey]!.add(contact2);
          }
        }
      }
    }

    if (duplicateGroups.isEmpty) {
      _showMessage(context, 'No duplicate contacts found');
      return;
    }

    // Show duplicates in a dialog
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => _DuplicatesDialog(
        duplicateGroups: duplicateGroups,
        onDelete: (contact) async {
          await model.deleteContact(contact);
          Navigator.of(ctx).pop();
          _findAndShowDuplicates(context);
        },
      ),
    );
  }

  /// Delete selected contacts
  Future<void> _deleteSelectedContacts(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contacts'),
        content: Text(
          'Are you sure you want to delete ${_selectedContactIds.length} contact(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final model =
          ScopedModel.of<ContactsModel>(context, rebuildOnChange: false);

      // Find contacts to delete by their IDs
      final contactsToDelete = model.contacts
          .where((contact) => _selectedContactIds.contains(contact.id))
          .toList();

      for (final contact in contactsToDelete) {
        await model.deleteContact(contact);
      }

      setState(() {
        _isSelectionMode = false;
        _selectedContactIds.clear();
      });

      if (mounted) {
        _showMessage(
          context,
          '${contactsToDelete.length} contact(s) deleted',
        );
      }
    }
  }

  /// Share selected contacts
  Future<void> _shareSelectedContacts(BuildContext context) async {
    final model =
        ScopedModel.of<ContactsModel>(context, rebuildOnChange: false);

    // Find contacts to share by their IDs
    final contactsToShare = model.contacts
        .where((contact) => _selectedContactIds.contains(contact.id))
        .toList();

    if (contactsToShare.isEmpty) {
      _showMessage(context, 'No contacts selected');
      return;
    }

    // Build vCard format for sharing
    final vCards = <String>[];
    for (final contact in contactsToShare) {
      final vCard = '''BEGIN:VCARD
VERSION:3.0
FN:${contact.name}
TEL:${contact.phoneNumber}
EMAIL:${contact.email}${contact.notes != null && contact.notes!.isNotEmpty ? '\nNOTE:${contact.notes}' : ''}
END:VCARD''';
      vCards.add(vCard);
    }

    final shareText = vCards.join('\n\n');

    try {
      await Share.share(
        shareText,
        subject: '${contactsToShare.length} Contact(s)',
      );

      setState(() {
        _isSelectionMode = false;
        _selectedContactIds.clear();
      });
    } catch (e) {
      if (mounted) {
        _showMessage(context, 'Failed to share contacts: ${e.toString()}');
      }
    }
  }

  /// Find duplicate contacts and show options to delete them
  Future<void> _findAndDeleteDuplicates(BuildContext context) async {
    final model =
        ScopedModel.of<ContactsModel>(context, rebuildOnChange: false);

    // Find duplicates: contacts with same phone number (normalized)
    final Map<String, List<Contact>> phoneGroups = {};

    for (final contact in model.contacts) {
      final normalizedPhone =
          contact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (normalizedPhone.isNotEmpty) {
        if (!phoneGroups.containsKey(normalizedPhone)) {
          phoneGroups[normalizedPhone] = [];
        }
        phoneGroups[normalizedPhone]!.add(contact);
      }
    }

    // Filter to only groups with duplicates
    final duplicateGroups =
        phoneGroups.entries.where((entry) => entry.value.length > 1).toList();

    if (duplicateGroups.isEmpty) {
      if (mounted) {
        _showMessage(context, 'No duplicate contacts found');
      }
      return;
    }

    // Build a list of duplicates for display
    final duplicatesList = <Contact>[];
    for (final group in duplicateGroups) {
      // Keep the first one, mark others as duplicates
      duplicatesList.addAll(group.value.skip(1));
    }

    if (mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Duplicates'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found ${duplicateGroups.length} duplicate group(s) with ${duplicatesList.length} duplicate contact(s):',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 250),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: duplicateGroups.length,
                    itemBuilder: (context, index) {
                      final group = duplicateGroups[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group ${index + 1}:',
                              style: Theme.of(ctx).textTheme.labelMedium,
                            ),
                            ...group.value.asMap().entries.map((entry) {
                              final isKeep = entry.key == 0;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(
                                  '${entry.value.name} (${entry.value.phoneNumber})${isKeep ? ' [KEEP]' : ' [DELETE]'}',
                                  style: TextStyle(
                                    color: isKeep
                                        ? Colors.green
                                        : Colors.redAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete Duplicates'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Delete all duplicate contacts
        for (final contact in duplicatesList) {
          await model.deleteContact(contact);
        }

        if (mounted) {
          _showMessage(
            context,
            'Deleted ${duplicatesList.length} duplicate contact(s)',
          );
        }
      }
    }
  }

  /// Show a message to the user
  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Dialog to display duplicate contacts with delete options
class _DuplicatesDialog extends StatelessWidget {
  final Map<String, List<Contact>> duplicateGroups;
  final Future<void> Function(Contact) onDelete;

  const _DuplicatesDialog({
    required this.duplicateGroups,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final totalDuplicates = duplicateGroups.values.fold<int>(
      0,
      (sum, group) => sum + group.length,
    );

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.content_copy_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
                '${duplicateGroups.length} Duplicate ${duplicateGroups.length == 1 ? 'Group' : 'Groups'}'),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: duplicateGroups.length,
          itemBuilder: (context, index) {
            final entry = duplicateGroups.entries.elementAt(index);
            final duplicates = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Text(
                    '${duplicates.length} contacts',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
                ...duplicates.map((contact) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 4),
                      leading: CircleAvatar(
                        backgroundImage: contact.imageFile != null
                            ? FileImage(contact.imageFile!)
                            : null,
                        child: contact.imageFile == null
                            ? Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(contact.name),
                      subtitle: Text(
                        contact.phoneNumber.isNotEmpty
                            ? contact.phoneNumber
                            : contact.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_rounded),
                        color: Colors.red,
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Contact'),
                              content: Text('Delete "${contact.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await onDelete(contact);
                          }
                        },
                      ),
                    )),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_SectionHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
