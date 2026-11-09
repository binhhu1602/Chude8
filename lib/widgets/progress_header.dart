import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// Thanh tiến độ dùng IMPLICIT ANIMATION:
/// - AnimatedContainer: tự nội suy chiều rộng + màu khi số việc xong thay đổi.
/// - AnimatedSwitcher: chuyển đổi mượt chữ "x/y" (fade + scale).
/// Chỉ cần setState giá trị mới, Flutter tự chạy animation từ giá trị cũ
/// sang giá trị mới.
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    final scheme = Theme.of(context).colorScheme;
    final duration = Motion.of(context, Motion.slow);
    final allDone = total > 0 && done == total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Tiến độ', style: TextStyle(fontSize: 16)),
              const Spacer(),
              AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                // Key thay đổi -> AnimatedSwitcher biết đây là widget mới.
                child: Text(
                  '$done/$total',
                  key: ValueKey('$done/$total'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => Container(
              height: 12,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: duration,
                curve: Motion.curve,
                width: constraints.maxWidth * ratio,
                decoration: BoxDecoration(
                  color: allDone ? Colors.green : scheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
