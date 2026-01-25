import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/family_details_screen.dart';
import 'screens/preferences_screen.dart';
import 'screens/profile_photos_screen.dart';
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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
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
      Navigator.of(context).pushReplacementNamed('/login');
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
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB47FFF), // Purple
              Color(0xFF5CB3FF), // Blue
              Color(0xFF4CD9A6), // Green
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container with elegant design
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(15),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo_1.png',
                      fit: BoxFit.contain,
                      width: 80,
                      height: 80,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Matrimony App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
