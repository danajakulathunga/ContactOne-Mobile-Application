# Import/Export Contacts Guide

## Overview

The contacts app now supports importing and exporting contacts via CSV files through a menu accessible from the Contact List page.

## Accessing the Feature

1. Open the Contact List page (main screen)
2. Tap the **3-dot menu icon** (⋮) in the **top-left corner** of the AppBar
3. Select either **Import Contacts** or **Export Contacts**

## Import Contacts

### How to Import

1. Tap **Import Contacts** from the menu
2. A file picker will open
3. Select a CSV file containing contacts
4. The app will import valid contacts and skip duplicates

### CSV Format

The CSV file must have the following structure:

```csv
Name,Phone Number,Email,Is Favorite,Notes
John Smith,+1234567890,john.smith@example.com,1,Friend from work
Jane Doe,+0987654321,jane.doe@example.com,0,College friend
```

**Column Details:**

- **Name** (required): Contact's full name
- **Phone Number** (required): Contact's phone number
- **Email** (required): Contact's email address
- **Is Favorite** (optional): 1 for favorite, 0 for not favorite
- **Notes** (optional): Additional notes about the contact

### Import Rules

- The first row is treated as a header and is skipped
- Contacts with missing name or phone number are skipped
- Duplicate contacts (same phone number) are automatically skipped
- Phone numbers are normalized (non-digit characters ignored) for duplicate detection
- A summary message shows how many contacts were imported and skipped

### Sample File

A sample import file (`sample_contacts_import.csv`) is included in the project root directory.

## Export Contacts

### How to Export

1. Tap **Export Contacts** from the menu
2. The app will request storage permission (if not already granted)
3. All contacts are exported to a CSV file
4. The file location is displayed in a message

### Export Location

- **Android**: `/storage/emulated/0/Download/contacts_export_[timestamp].csv`
- **iOS/Other**: Application Documents directory

### Export Format

The exported CSV follows the same format as import:

- Contains all contact fields (name, phone, email, favorite status, notes)
- File name includes timestamp: `contacts_export_1234567890.csv`
- Can be re-imported without data loss

## Permissions

### Android

The following permissions are required and will be requested automatically:

- `READ_EXTERNAL_STORAGE` (for import)
- `WRITE_EXTERNAL_STORAGE` (for export)
- `MANAGE_EXTERNAL_STORAGE` (for Android 11+)

### iOS

File access is handled through system file pickers and doesn't require explicit permissions.

## Error Handling

The app provides feedback for:

- Empty or invalid CSV files
- Import/export failures
- Permission denials
- File access issues

All errors are displayed via snackbar messages at the bottom of the screen.

## Tips

- Always back up your contacts before importing to avoid conflicts
- Exported files can be shared with other devices
- Use the export feature regularly to create backups
- Ensure CSV files follow the exact format to avoid import errors
