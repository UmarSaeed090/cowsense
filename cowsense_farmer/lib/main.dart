import 'package:cowsense/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'firebase_options.dart';
import 'services/sensor_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/tile_cache_service.dart';
import 'providers/sensor_provider.dart';
import 'providers/animal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/veterinarian_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/forget_password_screen.dart';
import 'screens/add_animal_screen.dart';
import 'screens/animals_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_chat.dart';
import 'screens/appointments_screen.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'services/chat_service.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Hive
  final storageService = StorageService();
  await storageService.initialize();

  Gemini.init(apiKey: 'AIzaSyBRxTMsaDlzPC7gzNhkdOfxKK9zIFiJOCM');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterNativeSplash.remove();
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize tile cache service for maps
  await TileCacheService().init();

  runApp(const CowSenseApp());
}

class CowSenseApp extends StatelessWidget {
  const CowSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sensorService = SensorService();
    final notificationService = NotificationService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final provider = SensorProvider(sensorService, notificationService);
            // Set the sensor provider in the notification service
            notificationService.sensorProvider = provider;
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<SensorProvider, AnimalProvider>(
          create: (context) => AnimalProvider(
            Provider.of<SensorProvider>(context, listen: false),
          ),
          update: (context, sensorProvider, previous) =>
              previous ?? AnimalProvider(sensorProvider),
        ),
        ChangeNotifierProvider(create: (_) => VeterinarianProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider(ChatService())),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            navigatorKey: authProvider.navigatorKey,
            debugShowCheckedModeBanner: false,
            scrollBehavior: const MaterialScrollBehavior(),
            title: 'CowSense',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  primary: const Color(0xFFCB2213),
                  onPrimaryContainer: Colors.white),
              useMaterial3: true,
            ),
            home: const AppRouter(),
            routes: {
              '/auth': (context) => const AuthScreen(),
              '/home': (context) => const HomeScreen(),
              '/forget-password': (context) => const ForgetPasswordScreen(),
              '/add-animal': (context) => const AddAnimalScreen(),
              '/animals': (context) => const AnimalsScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/ai-chat': (context) => const Chat(),
              '/appointments': (context) => const AppointmentsScreen(),
              '/change_password': (context) => const ChangePasswordScreen(),
            },
          );
        },
      ),
    );
  }
}
