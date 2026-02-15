import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Title with logo colors
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      "Find Your",
                      style: TextStyle(
                        color: AppColors.primaryCyan, // Turquoise from logo
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      "Perfect Match!",
                      style: TextStyle(
                        color: AppColors.primaryBlue, // Deep blue from logo
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Decorative Circular Profile Pattern
              SizedBox(
                height: size.height * 0.35,
                width: size.width,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Dashed Circle
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.3),
                          width: 1.5,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                    // Inner Dashed Circle
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),

                    // Profile Avatars positioned around
                    _buildAnimatedAvatar(
                      0,
                      -140,
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
                    ),
                    _buildAnimatedAvatar(
                      120,
                      -60,
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                    ),
                    _buildAnimatedAvatar(
                      -120,
                      -60,
                      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
                    ),
                    _buildAnimatedAvatar(
                      80,
                      80,
                      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
                    ),
                    _buildAnimatedAvatar(
                      -80,
                      80,
                      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                    ),

                    // Center Logo (Focus)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.primaryCyan, // Turquoise border
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryCyan.withOpacity(0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/vivah_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Description text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Let's find you a partner either casual, serious or a marriage relationship.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Button with gradient matching logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32.5),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.primaryCyan, // Turquoise
                        AppColors.primaryBlue, // Deep blue
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryCyan.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.5),
                      ),
                    ),
                    child: const Text(
                      "Explore Now",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(double x, double y, String url) {
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryCyan.withOpacity(0.6),
            width: 2,
          ),
        ),
        child: CircleAvatar(backgroundImage: NetworkImage(url)),
      ),
    );
  }
}