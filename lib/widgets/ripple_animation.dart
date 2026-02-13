import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/api_service.dart';

class RipplesAnimation extends StatefulWidget {
  final Widget? child;
  final String? profileImageUrl;
  final double size;
  final Color color;
  final String? loadingText;

  const RipplesAnimation({
    Key? key,
    this.child,
    this.profileImageUrl,
    this.size = 120.0,
    this.color = const Color(0xFF00BCD4),
    this.loadingText,
  }) : super(key: key);

  @override
  _RipplesAnimationState createState() => _RipplesAnimationState();
}

class _RipplesAnimationState extends State<RipplesAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomPaint(
          painter: CirclePainter(
            _controller,
            color: widget.color,
          ),
          child: SizedBox(
            width: widget.size * 2.5,
            height: widget.size * 2.5,
            child: _button(),
          ),
        ),
        if (widget.loadingText != null) ...[
          const SizedBox(height: 20),
          Text(
            widget.loadingText!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }

  Widget _button() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            image: widget.profileImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(ApiService.getImageUrl(widget.profileImageUrl!)),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.profileImageUrl == null
              ? const Icon(Icons.person, color: Colors.grey, size: 40)
              : null,
        ),
      ),
    );
  }
}

class CirclePainter extends CustomPainter {
  final Animation<double> _animation;
  final Color color;

  CirclePainter(this._animation, {required this.color})
      : super(repaint: _animation);

  void circle(Canvas canvas, Rect rect, double value) {
    double opacity = (1.0 - (value / 2.0)).clamp(0.0, 1.0);
    Color adjustedColor = color.withOpacity(opacity * 0.5);

    double size = rect.width / 2;
    double area = size * size;
    double radius = math.sqrt(area * value / 2);

    final Paint paint = Paint()
      ..color = adjustedColor
      ..style = PaintingStyle.fill;

    // Draw the filled circle
    canvas.drawCircle(rect.center, radius, paint);

    // Draw the white border
    final Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.8) // Slightly more transparent than full opacity to blend better
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(rect.center, radius, borderPaint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);

    for (int wave = 1; wave >= 0; wave--) {
      circle(canvas, rect, wave + _animation.value);
    }
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => true;
}
