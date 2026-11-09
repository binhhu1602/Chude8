import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/motion.dart';

/// Màn hình chi tiết.
/// - Hero: tiêu đề "bay" từ danh sách sang màn hình này (shared element).
/// - AnimatedCrossFade: chuyển giữa 2 trạng thái "Đang làm" / "Đã xong".
/// - TweenAnimationBuilder: thẻ thông tin phóng to nhẹ khi xuất hiện
///   (implicit animation chạy một lần, không cần tự quản lý controller).
class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final duration = Motion.of(context, Motion.slow);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết công việc')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'task-${task.id}',
              child: Material(
                type: MaterialType.transparency,
                child: Text(
                  task.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedCrossFade(
              duration: duration,
              crossFadeState: task.done
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const Chip(
                avatar: Icon(Icons.timelapse),
                label: Text('Đang thực hiện'),
              ),
              secondChild: const Chip(
                avatar: Icon(Icons.check, color: Colors.green),
                label: Text('Đã hoàn thành'),
              ),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1),
              duration: duration,
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Mã công việc: #${task.id}\n'
                    'Mẹo: quay lại danh sách và chạm vào công việc để đổi '
                    'trạng thái, rồi mở lại để thấy hiệu ứng chuyển trạng thái.',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
