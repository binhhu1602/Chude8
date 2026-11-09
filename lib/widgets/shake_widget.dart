import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/motion.dart';

/// Hiệu ứng "lắc" dùng EXPLICIT ANIMATION với AnimationController.
/// Dùng để báo lỗi khi người dùng bấm "Thêm" mà chưa nhập tên công việc.
///
/// Nguyên tắc quản lý tài nguyên:
/// 1. Khởi tạo controller trong initState với `vsync: this`
///    (SingleTickerProviderStateMixin) -> ticker chỉ chạy khi widget đang
///    hiển thị, không tốn CPU/pin khi ở màn hình khác.
/// 2. Luôn gọi controller.dispose() trong dispose() để tránh rò rỉ bộ nhớ.
/// 3. Dùng AnimatedBuilder + tham số `child` để chỉ rebuild phần chuyển động.
class ShakeWidget extends StatefulWidget {
  const ShakeWidget({super.key, required this.child});

  final Widget child;

  @override
  State<ShakeWidget> createState() => ShakeWidgetState();
}

class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  /// Gọi từ bên ngoài (qua GlobalKey) để kích hoạt hiệu ứng.
  void shake() {
    if (Motion.reduced(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose(); // GIẢI PHÓNG TÀI NGUYÊN
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child, // child không bị build lại mỗi frame
      builder: (context, child) {
        // Dao động hình sin, biên độ giảm dần về 0.
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
