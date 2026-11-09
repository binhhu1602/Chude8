/// Model đơn giản cho một công việc.
class Task {
  Task({required this.id, required this.title, this.note = '', this.done = false});

  final int id;
  final String title;
  final String note;
  bool done;
}
