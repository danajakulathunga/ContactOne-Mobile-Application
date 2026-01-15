import 'package:contacts_app/ui/contact_list/contact_list_page.dart';
import 'package:contacts_app/ui/model/contact_model.dart';
import 'package:contacts_app/ui/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scoped_model/scoped_model.dart';

void main() {
  // Optimize app launch: defer heavy initialization to after UI renders
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ContactsModel _contactsModel;

  @override
  void initState() {
    super.initState();
    _contactsModel = ContactsModel();
    // Load contacts asynchronously after the UI renders (splash screen shows immediately)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contactsModel.loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel(
      model: _contactsModel,
      child: MaterialApp(
        title: 'Contacts',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
        home: const SplashScreen(),
      ),
    );
  }

  // Build the Material Design theme with Inter font and custom styling
  ThemeData _buildTheme(Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4F46E5),
        brightness: brightness,
      ),
    );

    final textTheme = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F7FB)
          : const Color(0xFF0F1115),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: base.appBarTheme.copyWith(
        elevation: 0,
        centerTitle: true,
        backgroundColor: brightness == Brightness.light
            ? const Color(0xFF0891B2) // Modern cyan/teal color
            : const Color(0xFF0E7490), // Slightly darker for dark mode
        foregroundColor: Colors.white,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1A1D24),
      ),
    );
  }
}
