import 'package:flutter/material.dart';

/// A [PageRoute] with no transition animation (instant page change).
class NoTransitionRoute<T> extends MaterialPageRoute<T> {
  NoTransitionRoute({required super.builder});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
