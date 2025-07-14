import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A standalone loader animation widget that displays a cow animation.
class LoaderAnimationWidget extends StatefulWidget {
  /// The width of the animation, defaults to 400.
  final double? width;

  /// The height of the animation, defaults to 250.
  final double? height;

  /// Path to the Lottie animation file.
  final String animationPath;

  /// Optional background color.
  final Color? backgroundColor;

  const LoaderAnimationWidget({
    super.key,
    this.width = 400,
    this.height = 250,
    this.animationPath = 'assets/jsons/Cow-loader.json',
    this.backgroundColor,
  });

  @override
  State<LoaderAnimationWidget> createState() => _LoaderAnimationWidgetState();
}

class _LoaderAnimationWidgetState extends State<LoaderAnimationWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: Center(
        child: Lottie.asset(
          widget.animationPath,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          animate: true,
        ),
      ),
    );
  }
}
