import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Add delay to ensure main menu is ready before navigation
    // Native splash screen is handled by the system
    // Delay set to 2.5 seconds to allow users to read 13-15 words comfortably
    // (Average reading speed: 3-4 words/second, so 13-15 words need ~3.5-4 seconds total)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (mounted) {
          context.go('/');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen image that fills entire screen
    // Native splash screen will be shown by the system, this ensures smooth transition
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Center(
          child: Image.asset(
            'assets/images/splash_screen.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}
