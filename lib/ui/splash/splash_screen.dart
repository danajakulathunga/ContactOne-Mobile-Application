import 'dart:ui';

import 'package:contacts_app/ui/contact_list/contact_list_page.dart';
import 'package:flutter/material.dart';

/// Premium splash (launch) screen displayed when the app starts.
/// Shows a gradient background, logo, caption, and footer text.
/// Automatically navigates to the contact list after a brief delay.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Manages splash screen state and navigation timing.
class _SplashScreenState extends State<SplashScreen> {
  /// Duration to display the splash screen before navigation (2.0 seconds).
  static const _displayDuration = Duration(milliseconds: 2000);

  /// Duration for the fade transition animation (0.48 seconds).
  static const _transitionDuration = Duration(milliseconds: 480);

  @override
  void initState() {
    super.initState();
    _startNavigation();
  }

  /// Triggers delayed navigation to the contact list after display duration.
  void _startNavigation() {
    // Wait briefly, then replace the stack with the contact list using a fade.
    Future.delayed(_displayDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(_buildRoute());
    });
  }

  /// Builds the route transition to the contact list with a fade effect.
  /// Uses [_transitionDuration] for smooth animation.
  /// Replaces the current route so back button doesn't return to splash.
  PageRouteBuilder<void> _buildRoute() {
    return PageRouteBuilder<void>(
      transitionDuration: _transitionDuration,
      pageBuilder: (context, animation, secondaryAnimation) =>
          const ContactListPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        final blurAnimation =
            Tween<double>(begin: 0, end: 8).animate(curvedAnimation);

        return AnimatedBuilder(
          animation: blurAnimation,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Blur the outgoing splash beneath the incoming page.
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: blurAnimation.value,
                    sigmaY: blurAnimation.value,
                  ),
                  child: const SizedBox.expand(),
                ),
                FadeTransition(
                  opacity: curvedAnimation,
                  child: child,
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds the main splash screen UI.
  /// Displays gradient background, centered logo & caption, and footer text.
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        /// Linear gradient background: dark teal to bright teal (top-left to bottom-right).
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF02335E), // Dark teal (start)
              Color(0xFF1FA3BA), // Bright teal (end)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            /// Centered content: logo and caption.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _SplashPhoto(),
                  const SizedBox(height: 20),
                  Text(
                    'Stay connected, stay organized.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.92),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            /// Footer text at the bottom of the screen.
            Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: Text(
                '© 2026 All rights reserved. Developed by DVK',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.58),
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Displays the splash screen photo asset with rounded corners.
/// Loads and renders the image with high quality.
class _SplashPhoto extends StatelessWidget {
  const _SplashPhoto();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,

      /// Rounded container for the splash photo.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),

        /// Load and display the splash photo asset.
        child: Image.asset(
          'lib/ui/splash/spash_screen_picture/splash_photo.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
