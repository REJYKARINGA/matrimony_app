import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/family_details_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/profile_photos_screen.dart';
import 'screens/landing_screen.dart';
import 'services/auth_provider.dart';
import 'services/navigation_provider.dart';
import 'utils/theme_provider.dart';
import 'models/user_model.dart';

void main() {
  runApp(const MatrimonyApp());
}

class MatrimonyApp extends StatelessWidget {
  const MatrimonyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Matrimony App',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/create-profile': (context) => const CreateProfileScreen(),
              '/home': (context) => const HomeScreen(),
              '/preferences': (context) => const PreferencesScreen(),
              '/profile-photos': (context) => const ProfilePhotosScreen(),
              '/landing': (context) => const LandingScreen(),
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller for the loading bar
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    
    _navigateToHome();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 2), () {});

    // Check if user is already logged in
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool isLoggedIn = await authProvider.loadCurrentUserWithProfile();

    if (isLoggedIn) {
      // Check if user has completed their profile
      final user = authProvider.user;
      if (user != null) {
        // Check if user is admin - admins skip profile creation
        if (user.role == 'admin') {
          // Admin users go directly to home
          Navigator.of(context).pushReplacementNamed('/home');
        } else if (user.userProfile == null) {
          // Regular user hasn't created a profile at all, redirect to create profile screen
          Navigator.of(context).pushReplacementNamed('/create-profile');
        } else {
          // Check if profile is complete (has essential information)
          final profile = user.userProfile!;
          if (_isProfileComplete(profile)) {
            // Profile is complete, go to home
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            // Profile exists but is incomplete, redirect to create profile screen to complete it
            Navigator.of(context).pushReplacementNamed('/create-profile');
          }
        }
      } else {
        // User is logged in but somehow user object is null
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/landing');
    }
  }

  /// Check if the user profile is complete with essential information
  bool _isProfileComplete(UserProfile profile) {
    // Define what constitutes a complete profile
    // At minimum, a complete profile should have:
    // - Names
    // - Date of birth
    // - Gender
    // - Basic location (city/district/state)
    // - Religion/caste information
    // - Education/occupation

    return profile.firstName.isNotEmpty &&
        profile.lastName.isNotEmpty &&
        profile.dateOfBirth != null &&
        profile.gender != null &&
        profile.gender!.isNotEmpty &&
        ((profile.city != null && profile.city!.isNotEmpty) ||
            (profile.district != null && profile.district!.isNotEmpty) ||
            (profile.state != null && profile.state!.isNotEmpty)) &&
        profile.religion != null &&
        profile.religion!.isNotEmpty &&
        profile.education != null &&
        profile.education!.isNotEmpty &&
        profile.occupation != null &&
        profile.occupation!.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white, // White background to match logo
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container with elegant design
              Container(
                width: 200,
                height: 200,
                child: Image.asset(
                  'assets/images/vivah_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Vivah4Ever',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2DC1D7), // Turquoise from logo
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kerala Matrimony',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0E70B3), // Deep blue from logo
                ),
              ),
              const SizedBox(height: 40),
              // Linear Progress Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 80),
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _animation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF2DC1D7), // Turquoise
                                Color(0xFF0E70B3), // Deep blue
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}