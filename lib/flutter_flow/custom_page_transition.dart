import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum PageTransitionType {
  fade,
  rightToLeft,
  leftToRight,
  topToBottom,
  bottomToTop,
  scale,
  rotate,
  size,
  rightToLeftWithFade,
  leftToRightWithFade,
  theme,
}

class PageTransition<T> extends PageRouteBuilder<T> {
  final Widget child;
  final PageTransitionType type;
  final Curve curve;
  final Alignment alignment;
  final Duration duration;
  final Duration reverseDuration;
  final PageRouteBuilder<T>? childCurrent;

  PageTransition({
    required this.child,
    required this.type,
    this.childCurrent,
    this.curve = Curves.linear,
    this.alignment = Alignment.center,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 300),
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionDuration: duration,
          reverseTransitionDuration: reverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            switch (type) {
              case PageTransitionType.fade:
                return FadeTransition(opacity: animation, child: child);
              case PageTransitionType.rightToLeft:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: curve)),
                  child: child,
                );
              case PageTransitionType.leftToRight:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: curve)),
                  child: child,
                );
              case PageTransitionType.topToBottom:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: curve)),
                  child: child,
                );
              case PageTransitionType.bottomToTop:
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: curve)),
                  child: child,
                );
              case PageTransitionType.scale:
                return ScaleTransition(
                  scale: CurvedAnimation(parent: animation, curve: curve),
                  alignment: alignment,
                  child: child,
                );
              default:
                return FadeTransition(opacity: animation, child: child);
            }
          },
        );
}
