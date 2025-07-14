import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:veteran/home/HomeScreen.dart';
import 'package:veteran/predictions/PredictionListPage.dart';
import 'package:veteran/predictions/PredictionReviewScreen.dart';
import 'package:veteran/profile/ProfileScreen.dart';
import 'package:veteran/reports/SharedHealthReport.dart';
import 'package:veteran/splash/SplashScreen.dart';
import 'auth/RegistrationScreen.dart';
import 'charts/chartScreen.dart';
import 'chatBot/Chat.dart';
import 'navigation/Navigation.dart';
import 'notification/NotificationsListScreen.dart';
import 'theme/app_theme.dart';
import 'auth/EmailVerificationScreen.dart';
import 'auth/ForgotPasswordScreen.dart';
import 'auth/SignInScreen.dart';
import 'auth/SignUpScreen.dart';
import 'package:connectivity_watcher/connectivity_watcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Gemini.init(apiKey: 'AIzaSyBRxTMsaDlzPC7gzNhkdOfxKK9zIFiJOCM');
  runApp(VeteranApp());
}

class VeteranApp extends StatelessWidget {
  const VeteranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ZoConnectivityWrapper(
      connectivityStyle:
          NoConnectivityStyle.SNACKBAR, // Set to show Snackbar on no internet
      builder: (context, connectionKey) {
        return MaterialApp(
          title: 'Veteran App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system, // system light/dark mode
          debugShowCheckedModeBanner: false,
          initialRoute: '/splash',
          navigatorKey:
              connectionKey, // Add navigatorKey to handle connectivity changes
          routes: {
            // SplashScreen
            '/splash': (_) => const SplashScreen(),

            // Auth
            '/login': (_) => const SignInScreen(),
            '/signUp': (_) => const SignUpScreen(),
            '/registration': (_) => const Registrationscreen(),
            '/forgotPassword': (_) => const ForgetPasswordScreen(),
            '/emailVerification': (_) => const EmailVerificationScreen(),

            // Dashboard
            '/home': (_) => const HomeScreen(),
            '/navigation': (_) => const Navigation(),
            '/notifications': (_) => NotificationsScreen(),

            // Profiles
            '/profile': (_) => const ProfileScreen(),

            // Predictions
            '/prediction-review': (_) => PredictionReviewPage(),
            '/prediction-list': (_) => PredictionListPage(),

            // Reports
            '/shared-health-report': (_) => const SharedHealthReportsScreen(),
            '/chartsScreen': (_) => const ChartsScreen(),

            // Chat
            '/chat': (_) => Chat(),
          },
        );
      },
    );
  }
}
