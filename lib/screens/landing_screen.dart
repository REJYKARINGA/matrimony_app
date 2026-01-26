import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFB47FFF), // Purple
              const Color(0xFF5CB3FF), // Blue
              const Color(0xFF4CD9A6), // Green
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Logo and Title
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/images/app_logo_1.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      "Find Your",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      "Perfect Date!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Decorative Circular Profile Pattern (Simulating Image 1)
              SizedBox(
                height: size.height * 0.4,
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
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                          style: BorderStyle.solid, // Flutter doesn't native dash, but solid thin looks good
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
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),
                    
                    // Profile Avatars positioned around
                    _buildAnimatedAvatar(0, -140, 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150'),
                    _buildAnimatedAvatar(120, -60, 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150'),
                    _buildAnimatedAvatar(-120, -60, 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150'),
                    _buildAnimatedAvatar(80, 80, 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150'),
                    _buildAnimatedAvatar(-80, 80, 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150'),
                    
                    // Center Avatar (Focus)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "Let's find you a partner either casual, serious or a marriage relationship.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Container(
                  width: double.infinity,
                  height: 65,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6A5AE0),
                      elevation: 0,
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
              const SizedBox(height: 40),
            ],
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
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
        ),
        child: CircleAvatar(
          backgroundImage: NetworkImage(url),
        ),
      ),
    );
  }
}
