import 'package:cowsense/widgets/loader_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/veterinarian_provider.dart';
import '../providers/animal_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
// import 'package:flutter_native_splash/flutter_native_splash.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  bool _isInitializing = true;

  @override
  void initState() {
    _initializeApp();
    super.initState();
  }

  Future<void> _initializeApp() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final veterinarianProvider =
          Provider.of<VeterinarianProvider>(context, listen: false);
      final animalProvider =
          Provider.of<AnimalProvider>(context, listen: false);
      final sensorProvider =
          Provider.of<SensorProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Initialize all providers in parallel
      await Future.wait<void>([
        Future(() => veterinarianProvider.initialize(auth.user!.uid)),
        Future(() => animalProvider.initialize(auth.user!.uid)),
        Future(() => sensorProvider.initialize(auth.user!.uid)),
        Future(() => chatProvider.initialize(auth.user!.uid)),
      ]);
    } catch (e) {
      debugPrint('Error during initialization: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Show loading indicator while initializing
        if (_isInitializing) {
          return const Scaffold(
            body: Center(
              child: LoaderAnimationWidget(),
            ),
          );
        }

        // Initialize providers when auth state changes
        if (auth.isAuthenticated) {
          // Use a post-frame callback to avoid setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final veterinarianProvider =
                Provider.of<VeterinarianProvider>(context, listen: false);
            if (veterinarianProvider.userId == null) {
              veterinarianProvider.setUserId(auth.user!.uid);
              // Load appointments separately after the build phase
              veterinarianProvider.loadAnimalAppointments(auth.user!.uid);
            }
          });
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
