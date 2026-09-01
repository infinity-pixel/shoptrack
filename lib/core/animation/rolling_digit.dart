import 'package:flutter/material.dart';

/// A widget that animates numeric value changes using a per-digit rolling odometer effect.
class RollingDigitText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  const RollingDigitText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<RollingDigitText> createState() => _RollingDigitTextState();
}

class _RollingDigitTextState extends State<RollingDigitText> {
  @override
  Widget build(BuildContext context) {
    final List<String> characters = widget.text.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: characters.asMap().entries.map((entry) {
        final int index = entry.key;
        final String char = entry.value;
        final bool isDigit = RegExp(r'\d').hasMatch(char);

        if (!isDigit) {
          return Text(char, style: widget.style);
        }

        return RollingDigit(
          key: ValueKey('digit_$index'), // Keyed by position to handle alignment
          digit: char,
          style: widget.style,
          duration: widget.duration,
          curve: widget.curve,
        );
      }).toList(),
    );
  }
}

class RollingDigit extends StatefulWidget {
  final String digit;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  const RollingDigit({
    super.key,
    required this.digit,
    required this.style,
    required this.duration,
    required this.curve,
  });

  @override
  State<RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<RollingDigit> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  String _previousDigit = '';
  String _currentDigit = '';

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.digit;
    _previousDigit = widget.digit;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
  }

  @override
  void didUpdateWidget(RollingDigit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.digit != _currentDigit) {
      _previousDigit = _currentDigit;
      _currentDigit = widget.digit;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine a reasonable height based on font size
    final double fontSize = widget.style.fontSize ?? 14.0;
    final double height = fontSize * 1.3;

    return SizedBox(
      height: height,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                if (_animation.value < 1.0)
                  Transform.translate(
                    offset: Offset(0, -_animation.value * height),
                    child: Text(_previousDigit, style: widget.style),
                  ),
                Transform.translate(
                  offset: Offset(0, (1 - _animation.value) * height),
                  child: Text(_currentDigit, style: widget.style),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
