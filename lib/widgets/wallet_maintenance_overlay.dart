import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class WalletMaintenanceOverlay extends StatefulWidget {
  final Widget child;
  const WalletMaintenanceOverlay({super.key, required this.child});

  @override
  State<WalletMaintenanceOverlay> createState() => _WalletMaintenanceOverlayState();
}

class _WalletMaintenanceOverlayState extends State<WalletMaintenanceOverlay>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _iconController;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(); // Slow continuous rotation

    _glowAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Clean, light background
      body: Stack(
        children: [
          // Animated Background Glows
          Positioned(
            top: -100,
            left: -50,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, _) => Transform.scale(
                scale: _glowAnim.value,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryGreen.withOpacity(0.08),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.1),
                        blurRadius: 100,
                        spreadRadius: 50,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, _) => Transform.scale(
                scale: 2.0 - _glowAnim.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.tealAccent.withOpacity(0.05),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withOpacity(0.08),
                        blurRadius: 100,
                        spreadRadius: 40,
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Main Content Area with Glassmorphism
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7), // Light frosted glass
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white, // Crisp white border
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04), // Soft, subtle shadow
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated Icon Stack
                            SizedBox(
                              width: 120,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _iconController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _iconController.value * 2 * 3.14159,
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      Icons.settings_suggest_rounded,
                                      size: 80,
                                      color: AppColors.primaryGreen.withOpacity(0.15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primaryGreen,
                                          AppColors.midnightEmerald,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryGreen.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        )
                                      ],
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 42,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Title
                            const Text(
                              'System Upgrade',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87, // Dark text for light theme
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Subtitle
                            const Text(
                              'We are upgrading our payment system to serve you better.\nWallet features will come soon!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.black54, // Medium dark text for light theme
                                height: 1.6,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Custom Animated Loading Bar
                            _buildCustomLoadingBar(),
                            const SizedBox(height: 48),
                            // Contact Support Info
                            _buildContactSupport(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomLoadingBar() {
    return Container(
      width: 160,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15), // Light gray track
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedBuilder(
        animation: _bgController,
        builder: (context, _) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (_bgController.value * 0.6) + 0.2, // Pulses between 20% and 80% width
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryGreen.withOpacity(0.4),
                    AppColors.primaryGreen,
                    AppColors.primaryGreen.withOpacity(0.4),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactSupport() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Contact Customer Assistant Team',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  const Text(
                    '+91 79948 70262',
                    style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 6),
                  const Text(
                    'WhatsApp',
                    style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              const Text(
                'support@nikkahmatch.com',
                style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
