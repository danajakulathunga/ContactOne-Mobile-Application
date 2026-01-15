# ContactOne Mobile Application 📱

A feature-rich, modern contacts management application built with Flutter. ContactOne provides a seamless experience for managing your contacts with an elegant UI, powerful features, and cross-platform support.

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

### Core Functionality

- **Contact Management**
  - Create, read, update, and delete contacts
  - Store contact name, phone number, email, and notes
  - Custom profile pictures for each contact
  - Alphabetically sorted contact list with section headers

### Advanced Features

- **Search & Filter**

  - Real-time search functionality
  - Filter contacts by favorites
  - Quick access to frequently used contacts

- **Favorites System**

  - Mark contacts as favorites with a single tap
  - Dedicated favorites view
  - Star icon indicator for quick identification

- **Import/Export**

  - Import contacts from CSV files
  - Export all contacts to CSV format
  - Automatic duplicate detection during import
  - Bulk contact management capabilities

- **Interactive UI Elements**

  - Swipe-to-delete functionality using flutter_slidable
  - Shimmer loading effects for smooth UX
  - Pull-to-refresh contacts list
  - Smooth animations and transitions

- **Communication Integration**

  - Direct phone call integration (tap phone number)
  - Email client integration (tap email address)
  - Share contact information with other apps

- **Image Management**
  - Add contact photos from camera or gallery
  - Automatic image compression and storage
  - Circular avatar display with fallback initials

### User Experience

- **Modern Design**

  - Material Design 3 (Material You) components
  - Inter font family via Google Fonts
  - Custom color scheme with teal/cyan accents
  - Elegant card-based layout with rounded corners

- **Dark Mode Support**

  - System-aware theme switching
  - Optimized colors for both light and dark modes
  - Consistent experience across theme modes

- **Splash Screen**
  - Custom branded splash screen
  - Smooth transition to main app
  - Asynchronous data loading

## 🏗️ Architecture

The app follows a clean architecture pattern with separation of concerns:

```
lib/
├── main.dart                 # App entry point
├── data/                     # Data layer
│   ├── contact.dart          # Contact model
│   └── db/                   # Database handling
├── ui/                       # Presentation layer
│   ├── contact/              # Contact detail screens
│   │   ├── contact_create_page.dart
│   │   ├── contact_edit_page.dart
│   │   └── widget/
│   ├── contact_list/         # Contact list screen
│   │   ├── contact_list_page.dart
│   │   └── widget/
│   ├── model/                # View models
│   │   └── contact_model.dart
│   └── splash/               # Splash screen
│       └── splash_screen.dart
└── utils/                    # Utilities and helpers
```

### State Management

- **Scoped Model**: Lightweight state management solution
- Reactive UI updates
- Centralized state for contact operations

### Data Persistence

- **Sembast**: NoSQL local database
- Lightweight and efficient
- JSON-based storage
- Fast query performance

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/danajakulathunga/ContactOne-Mobile-Application.git
   cd ContactOne-Mobile-Application
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the app**

   ```bash
   # For Android
   flutter run

   # For iOS
   flutter run -d ios

   # For Web
   flutter run -d chrome

   # For Windows
   flutter run -d windows
   ```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## 📦 Dependencies

### Core Dependencies

- **flutter**: Cross-platform UI framework
- **scoped_model**: State management solution
- **sembast**: NoSQL local database
- **path_provider**: Access to device file system paths

### UI & Design

- **google_fonts**: Custom fonts (Inter family)
- **cupertino_icons**: iOS-style icons
- **shimmer**: Loading animation effects
- **flutter_slidable**: Swipe actions for list items

### Functionality

- **image_picker**: Select images from gallery/camera
- **url_launcher**: Make calls and send emails
- **share_plus**: Share contact information
- **file_picker**: Import/export file selection
- **csv**: CSV file parsing and generation
- **permission_handler**: Runtime permissions management
- **faker**: Generate fake test data

## 📄 Import/Export Guide

### Importing Contacts

1. Tap the 3-dot menu (⋮) in the top-left corner
2. Select **Import Contacts**
3. Choose a CSV file from your device
4. Contacts will be imported with automatic duplicate detection

**CSV Format:**

```csv
Name,Phone Number,Email,Is Favorite,Notes
John Smith,+1234567890,john.smith@example.com,1,Friend from work
Jane Doe,+0987654321,jane.doe@example.com,0,College friend
```

### Exporting Contacts

1. Tap the 3-dot menu (⋮) in the top-left corner
2. Select **Export Contacts**
3. Choose a location to save the CSV file
4. All contacts will be exported in CSV format

See [IMPORT_EXPORT_GUIDE.md](IMPORT_EXPORT_GUIDE.md) for detailed instructions.

## 🎨 Screenshots

_Add your app screenshots here_

## 🔒 Permissions

The app requires the following permissions:

### Android

- `READ_EXTERNAL_STORAGE`: Import contacts from CSV files
- `WRITE_EXTERNAL_STORAGE`: Export contacts to CSV files
- `CAMERA`: Take photos for contact pictures
- `CALL_PHONE`: Initiate phone calls (optional)

### iOS

- `NSPhotoLibraryUsageDescription`: Access photo library
- `NSCameraUsageDescription`: Access camera

## 🛠️ Troubleshooting

### Common Issues

**Issue**: App crashes on startup

- **Solution**: Run `flutter clean` and then `flutter pub get`

**Issue**: Images not displaying

- **Solution**: Check permissions and restart the app

**Issue**: Import/export not working

- **Solution**: Ensure storage permissions are granted

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer

**Danaja Kulathunga**

- GitHub: [@danajakulathunga](https://github.com/danajakulathunga)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- All package contributors
- Material Design 3 guidelines
- Google Fonts

## 📞 Support

For support, email danajakulathunga@example.com or open an issue in the repository.

---

**Made with ❤️ using Flutter**
