import 'package:flutter/material.dart';

/// A reusable loading indicator widget with consistent styling
/// across the application.
class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.message,
    this.strokeWidth = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = color ?? Theme.of(context).primaryColor;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Small inline loading indicator
  factory LoadingIndicator.small({Color? color}) {
    return LoadingIndicator(
      size: 20.0,
      strokeWidth: 2.0,
      color: color,
    );
  }

  /// Full-screen loading overlay
  static Widget overlay({String? message, Color? color}) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: LoadingIndicator(
        message: message,
        color: color ?? Colors.white,
      ),
    );
  }
}
