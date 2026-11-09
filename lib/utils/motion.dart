import 'package:flutter/material.dart';

/// Tập trung các thông số chuyển động ở một chỗ để toàn app đồng nhất.
///
/// - Thời lượng ngắn (150–350ms): đủ để người dùng thấy thay đổi
///   nhưng không bắt họ phải chờ.
/// - Tôn trọng cài đặt "Giảm chuyển động" của hệ điều hành
///   (MediaQuery.disableAnimations) -> trả về Duration.zero.
class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve curve = Curves.easeOutCubic;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
