import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/motion.dart';

/// Một dòng công việc kết hợp GESTURE + IMPLICIT ANIMATION:
/// - Chạm (tap)            -> đánh dấu xong: AnimatedContainer đổi màu/viền,
///                             AnimatedDefaultTextStyle gạch chữ, AnimatedScale icon.
/// - Vuốt trái (swipe)     -> Dismissible xóa công việc (có Undo).
/// - Nhấn giữ (long press) -> mở màn hình chi tiết (Hero + route tùy biến).
class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onOpen,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final duration = Motion.of(context, Motion.medium);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: AnimatedContainer(
        duration: duration,
        curve: Motion.curve,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: task.done
              ? Colors.green.withValues(alpha: 0.12)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: task.done ? Colors.green : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            onLongPress: onOpen,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  AnimatedScale(
                    duration: duration,
                    scale: task.done ? 1.15 : 1.0,
                    curve: Curves.easeOutBack,
                    child: Icon(
                      task.done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: task.done ? Colors.green : scheme.outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Hero(
                      tag: 'task-${task.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: AnimatedDefaultTextStyle(
                          duration: duration,
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                task.done ? scheme.outline : scheme.onSurface,
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          child: Text(task.title),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
