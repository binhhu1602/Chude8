import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/fade_slide_route.dart';
import '../utils/motion.dart';
import '../widgets/progress_header.dart';
import '../widgets/shake_widget.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

/// Màn hình chính: danh sách công việc.
///
/// Các hiệu ứng có trên màn hình này:
/// 1. AnimatedList        : công việc mới "mọc ra" (SizeTransition + Fade).
/// 2. ShakeWidget         : lắc ô nhập khi tên trống (AnimationController).
/// 3. ProgressHeader      : thanh tiến độ (AnimatedContainer, AnimatedSwitcher).
/// 4. TaskTile            : tap / swipe / long press (gesture + implicit anim).
/// 5. AnimatedOpacity     : thông báo "chưa có công việc".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _textController = TextEditingController();

  int _nextId = 4;
  final List<Task> _tasks = [
    Task(id: 1, title: 'Đọc tài liệu về AnimatedContainer'),
    Task(id: 2, title: 'Thử AnimationController + dispose'),
    Task(id: 3, title: 'Demo gesture vuốt để xóa'),
  ];

  @override
  void dispose() {
    _textController.dispose(); // controller nhập liệu cũng phải giải phóng
    super.dispose();
  }

  // ---------------- Thêm ----------------
  void _addTask() {
    final title = _textController.text.trim();
    if (title.isEmpty) {
      _shakeKey.currentState?.shake(); // phản hồi lỗi bằng chuyển động
      return;
    }
    _tasks.insert(0, Task(id: _nextId++, title: title));
    _listKey.currentState
        ?.insertItem(0, duration: Motion.of(context, Motion.slow));
    _textController.clear();
    setState(() {}); // cập nhật ProgressHeader
  }

  // ---------------- Đánh dấu xong ----------------
  void _toggle(Task task) => setState(() => task.done = !task.done);

  // ---------------- Xóa (vuốt) + Hoàn tác ----------------
  void _delete(Task task) {
    final index = _tasks.indexOf(task);
    if (index < 0) return;
    _tasks.removeAt(index);
    // Dismissible đã tự chạy hiệu ứng trượt + thu gọn,
    // nên AnimatedList chỉ cần gỡ item ngay (Duration.zero).
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => const SizedBox.shrink(),
      duration: Duration.zero,
    );
    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Đã xóa "${task.title}"'),
          action: SnackBarAction(
            label: 'HOÀN TÁC',
            onPressed: () {
              final i = index.clamp(0, _tasks.length);
              _tasks.insert(i, task);
              _listKey.currentState
                  ?.insertItem(i, duration: Motion.of(context, Motion.slow));
              setState(() {});
            },
          ),
        ),
      );
  }

  // ---------------- Mở chi tiết ----------------
  void _open(Task task) {
    Navigator.of(context).push(
      FadeSlideRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
  }

  /// Hiệu ứng khi một item được chèn vào AnimatedList.
  Widget _buildAnimatedItem(Task task, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve);
    return SizeTransition(
      sizeFactor: curved,
      child: FadeTransition(
        opacity: curved,
        child: TaskTile(
          task: task,
          onToggle: () => _toggle(task),
          onDelete: () => _delete(task),
          onOpen: () => _open(task),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Công việc hôm nay')),
      body: Column(
        children: [
          ProgressHeader(done: doneCount, total: _tasks.length),
          _buildInput(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Chạm: hoàn thành • Vuốt trái: xóa • Nhấn giữ: chi tiết',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                AnimatedList(
                  key: _listKey,
                  padding: const EdgeInsets.only(bottom: 80),
                  initialItemCount: _tasks.length,
                  itemBuilder: (context, index, animation) =>
                      _buildAnimatedItem(_tasks[index], animation),
                ),
                // IgnorePointer: lớp thông báo không chặn thao tác bên dưới.
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _tasks.isEmpty ? 1 : 0,
                    duration: Motion.of(context, Motion.medium),
                    child: const Center(
                      child: Text('🎉 Chưa có công việc nào',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ShakeWidget(
              key: _shakeKey,
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Nhập công việc mới...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addTask(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _addTask,
            icon: const Icon(Icons.add),
            label: const Text('Thêm'),
          ),
        ],
      ),
    );
  }
}
