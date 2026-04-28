import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

/// A bright, celebratory popup shown when the user receives an interest notification.
/// Call [InterestNotificationDialog.show] to display it.
class InterestNotificationDialog extends StatefulWidget {
  final String senderName;
  final String? senderPicUrl;
  final String message;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  const InterestNotificationDialog({
    Key? key,
    required this.senderName,
    required this.senderPicUrl,
    required this.message,
    required this.onView,
    required this.onDismiss,
  }) : super(key: key);

  static void show({
    required BuildContext context,
    required String senderName,
    String? senderPicUrl,
    required String message,
    required VoidCallback onView,
    required VoidCallback onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) => InterestNotificationDialog(
        senderName: senderName,
        senderPicUrl: senderPicUrl,
        message: message,
        onView: onView,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  State<InterestNotificationDialog> createState() => _InterestNotificationDialogState();
}

class _InterestNotificationDialogState extends State<InterestNotificationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _confettiCtrl;

  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _confettiAnim;

  @override
  void initState() {
    super.initState();

    // Entry animation
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);

    // Confetti spin
    _confettiCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _confettiAnim = Tween<double>(begin: 0, end: 2 * math.pi).animate(_confettiCtrl);

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.35),
            blurRadius: 40,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient header with confetti & avatar ──
          _buildHeader(),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
            child: Column(
              children: [
                const SizedBox(height: 4),

                // Congrats title
                ShaderMask(
                  shaderCallback: (b) => AppColors.primaryGradient.createShader(b),
                  child: const Text(
                    '🎉  Someone Likes You!',
                    style: TextStyle(
                      color: Colors.white, // painted by shader
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Message
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF444466),
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: 14),

                // "Keeps showing" reminder chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryCyan.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryCyan.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active_rounded,
                          color: AppColors.primaryCyan, size: 14),
                      const SizedBox(width: 6),
                      const Text(
                        'Reminding you until you read it',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // CTA — View Now
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: widget.onView,
                      icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        'VIEW NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Dismiss
                TextButton(
                  onPressed: widget.onDismiss,
                  child: const Text(
                    'REMIND ME LATER',
                    style: TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryCyan,
            const Color(0xFF2F89D6),
            AppColors.primaryBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating confetti dots
          AnimatedBuilder(
            animation: _confettiAnim,
            builder: (_, __) => CustomPaint(
              size: const Size(double.infinity, 170),
              painter: _ConfettiPainter(_confettiAnim.value),
            ),
          ),

          // Avatar (static, no pulse)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColors.primaryCyan.withOpacity(0.2),
                  backgroundImage: widget.senderPicUrl != null
                      ? NetworkImage(ApiService.getImageUrl(widget.senderPicUrl!))
                      : null,
                  child: widget.senderPicUrl == null
                      ? const Icon(Icons.person, size: 46, color: Colors.white)
                      : null,
                ),
              ),

              const SizedBox(height: 8),

              // Sender name
              Text(
                widget.senderName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Confetti Painter ────────────────────────────────────────────────────────
class _ConfettiPainter extends CustomPainter {
  final double angle;
  _ConfettiPainter(this.angle);

  static final List<Map<String, dynamic>> _dots = List.generate(18, (i) {
    final rand = math.Random(i * 7 + 3);
    return {
      'x': rand.nextDouble(),
      'y': rand.nextDouble(),
      'r': 3.0 + rand.nextDouble() * 5,
      'color': [
        Colors.white,
        const Color(0xFFFFC0CB),
        const Color(0xFFFFE066),
        const Color(0xFFB2EBF2),
        const Color(0xFFE8F5E9),
      ][i % 5],
      'speed': 0.5 + rand.nextDouble(),
      'offset': rand.nextDouble() * 2 * math.pi,
    };
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in _dots) {
      final dx = (dot['x'] as double) * size.width +
          math.sin(angle * (dot['speed'] as double) + (dot['offset'] as double)) * 10;
      final dy = (dot['y'] as double) * size.height +
          math.cos(angle * (dot['speed'] as double) + (dot['offset'] as double)) * 8;
      canvas.drawCircle(
        Offset(dx, dy),
        dot['r'] as double,
        Paint()
          ..color = (dot['color'] as Color).withOpacity(0.55)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.angle != angle;
}




