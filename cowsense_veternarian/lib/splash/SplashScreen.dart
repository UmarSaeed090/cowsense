import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));

    // final connectivity = await Connectivity().checkConnectivity();
    // if (connectivity == ConnectivityResult.none) {
    //   if (!mounted) return;
    //   _showNoInternetDialog();
    //   return;
    // }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload(); // Make sure we get the latest user information
        final refreshedUser = FirebaseAuth.instance.currentUser;

        // Check if user is still signed in and email is verified
        if (refreshedUser != null) {
          if (refreshedUser.emailVerified) {
            // Navigate to the navigation if the email is verified
            Navigator.pushReplacementNamed(context, '/navigation');
          } else {
            // If email is not verified, navigate to the email verification screen
            Navigator.pushReplacementNamed(context, '/emailVerification');
          }
        } else {
          // If the user is not signed in, navigate to the login screen
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // No user is logged in, navigate to the login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Network or Firebase error: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/splash.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.2)),
        ],
      ),
    );
  }
}

