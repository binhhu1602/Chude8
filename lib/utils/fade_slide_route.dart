import 'package:flutter/material.dart';

import 'motion.dart';

/// Hiệu ứng chuyển màn hình tùy biến: mờ dần + trượt nhẹ từ dưới lên.
/// PageRouteBuilder tự tạo và tự dispose AnimationController bên trong,
/// nên ta không phải quản lý controller thủ công.
class FadeSlideRoute<T> extends PageRouteBuilder<T> {
  FadeSlideRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: Motion.slow,
          reverseTransitionDuration: Motion.medium,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Motion.curve);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}
