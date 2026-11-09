# Chủ đề 8 – Hiệu ứng chuyển động (Animation) trong Flutter

> **Sản phẩm demo:** ứng dụng *Quản lý công việc* (to-do list) viết bằng Flutter.
> Mỗi thao tác của người dùng – thêm, hoàn thành, xóa, xem chi tiết – đều có một hiệu ứng chuyển động phù hợp,
> nhưng **không có hiệu ứng nào bắt người dùng phải chờ hoặc chặn thao tác**.

---

## Mục lục

0. [Yêu cầu đề bài và nơi đáp ứng](#0-yêu-cầu-đề-bài-và-nơi-đáp-ứng)
1. [Cài đặt và chạy chương trình](#1-cài-đặt-và-chạy-chương-trình)
2. [Cấu trúc dự án](#2-cấu-trúc-dự-án)
3. [Cơ sở lý thuyết](#3-cơ-sở-lý-thuyết)
4. [Các hiệu ứng trong chương trình](#4-các-hiệu-ứng-trong-chương-trình)
5. [Bảo đảm chuyển động không cản trở thao tác](#5-bảo-đảm-chuyển-động-không-cản-trở-thao-tác)
6. [Kịch bản demo](#6-kịch-bản-demo)
7. [Câu hỏi thường gặp](#7-câu-hỏi-thường-gặp)
8. [Kết luận](#8-kết-luận)

---

## 0. Yêu cầu đề bài và nơi đáp ứng

| Yêu cầu | Nội dung trong README | Code minh họa |
|---|---|---|
| Implicit animation (AnimatedContainer, các transition cơ bản) | [Mục 3.1](#31-implicit-animation--chuyển-động-ngầm-định) | `progress_header.dart`, `task_tile.dart`, `home_screen.dart` |
| AnimationController và quản lý tài nguyên animation | [Mục 3.2](#32-animationcontroller-và-quản-lý-tài-nguyên) | `shake_widget.dart` |
| Gesture, thời điểm dùng animation, tác động đến UX | [Mục 3.3](#33-gesture-thời-điểm-dùng-animation-và-trải-nghiệm-người-dùng) | `task_tile.dart` |
| Tích hợp hiệu ứng vào chương trình | [Mục 4](#4-các-hiệu-ứng-trong-chương-trình) (9 hiệu ứng) | toàn bộ `lib/` |
| Giải thích cách kích hoạt hiệu ứng | [Mục 4](#4-các-hiệu-ứng-trong-chương-trình), dòng **"Kích hoạt"** ở mỗi hiệu ứng | |
| Bảo đảm chuyển động không cản trở thao tác | [Mục 5](#5-bảo-đảm-chuyển-động-không-cản-trở-thao-tác) | `motion.dart`, `home_screen.dart` |

---

## 1. Cài đặt và chạy chương trình

**Yêu cầu:** Flutter SDK 3.x (đã thử với Flutter 3.44, Dart 3).

```bash
cd animation_demo
flutter pub get      # tải thư viện
flutter run          # chạy app, chọn thiết bị: Android / Chrome / Windows
flutter test         # chạy kiểm thử tự động
flutter analyze      # kiểm tra lỗi code
```

Dự án **không dùng thư viện ngoài**, chỉ dùng các widget có sẵn của Flutter.

---

## 2. Cấu trúc dự án

```
lib/
├── main.dart                        # Điểm khởi chạy app
├── models/
│   └── task.dart                    # Dữ liệu một công việc
├── utils/
│   ├── motion.dart                  # Thông số chuyển động dùng chung
│   └── fade_slide_route.dart        # Hiệu ứng chuyển màn hình
├── widgets/
│   ├── progress_header.dart         # Thanh tiến độ có animation
│   ├── shake_widget.dart            # Hiệu ứng "lắc" dùng AnimationController
│   └── task_tile.dart               # Một dòng công việc (gesture + animation)
└── screens/
    ├── home_screen.dart             # Màn hình danh sách
    └── task_detail_screen.dart      # Màn hình chi tiết
test/
└── widget_test.dart                 # Kiểm thử: thêm việc, đánh dấu hoàn thành
```

| File | Vai trò | Kỹ thuật animation chính |
|---|---|---|
| [main.dart](lib/main.dart) | Tạo `MaterialApp`, theme, mở `HomeScreen` | – |
| [task.dart](lib/models/task.dart) | Class `Task` gồm `id`, `title`, `done` | – |
| [motion.dart](lib/utils/motion.dart) | Gom thời lượng (150/250/350 ms), curve; tự tắt animation khi máy bật "Giảm chuyển động" | Quy chuẩn chung |
| [fade_slide_route.dart](lib/utils/fade_slide_route.dart) | Route chuyển trang tùy biến | `PageRouteBuilder`, `FadeTransition`, `SlideTransition` |
| [progress_header.dart](lib/widgets/progress_header.dart) | Thanh "Tiến độ x/y" | `AnimatedContainer`, `AnimatedSwitcher`, `ScaleTransition` |
| [shake_widget.dart](lib/widgets/shake_widget.dart) | Lắc ô nhập khi nhập sai | `AnimationController`, `AnimatedBuilder` |
| [task_tile.dart](lib/widgets/task_tile.dart) | Một dòng công việc, nhận tap / long press / swipe | `Dismissible`, `InkWell`, `AnimatedContainer`, `AnimatedScale`, `AnimatedDefaultTextStyle`, `Hero` |
| [home_screen.dart](lib/screens/home_screen.dart) | Ghép mọi thứ: ô nhập, danh sách, Undo | `AnimatedList`, `SizeTransition`, `FadeTransition`, `AnimatedOpacity` |
| [task_detail_screen.dart](lib/screens/task_detail_screen.dart) | Xem chi tiết một công việc | `Hero`, `AnimatedCrossFade`, `TweenAnimationBuilder` |

---

## 3. Cơ sở lý thuyết

Flutter có hai nhóm animation:

| | **Implicit animation** (ngầm định) | **Explicit animation** (tường minh) |
|---|---|---|
| Cách dùng | Đổi giá trị thuộc tính, widget tự chạy hiệu ứng | Tự tạo `AnimationController` và ra lệnh chạy |
| Ví dụ | `AnimatedContainer`, `AnimatedOpacity` | `AnimationController` + `AnimatedBuilder` / `XxxTransition` |
| Điều khiển | Chỉ có giá trị đích, `duration`, `curve` | Chạy, dừng, đảo chiều, lặp, chạy lại từ đầu |
| Quản lý vòng đời | Flutter tự lo | Lập trình viên phải tạo và `dispose` |
| Nên dùng khi | Hiệu ứng đơn giản khi trạng thái thay đổi | Cần điều khiển chủ động, hiệu ứng lặp, nhiều bước |

> **Quy tắc chọn:** thử implicit animation trước. Chỉ dùng `AnimationController` khi implicit không làm được.

### 3.1. Implicit animation – chuyển động ngầm định

**Khái niệm:** implicit animation là widget **tự chạy hiệu ứng khi giá trị thuộc tính của nó thay đổi**.

**Cơ chế:**

```
 Giá trị cũ (width = 0)
        │
        │  setState(() => ratio = 0.5)   ← lập trình viên chỉ đổi giá trị
        ▼
 Flutter tạo controller nội bộ, nội suy 0 → 0.5 trong `duration`, theo `curve`
        │
        ▼
 Giá trị mới (width = 0.5 * maxWidth)    ← mỗi frame vẽ một giá trị trung gian
```

Nếu giá trị đổi lần nữa trong lúc hiệu ứng đang chạy, animation **chuyển hướng ngay từ vị trí hiện tại**
chứ không nhảy về đầu. Nhờ vậy, người dùng chạm liên tục cũng không làm hiệu ứng bị giật.

**AnimatedContainer** là widget implicit phổ biến nhất. Nó tự animate `width`, `height`, `color`,
`padding`, `margin`, `decoration` (bo góc, viền, màu nền)…

Ví dụ trong dự án ([progress_header.dart](lib/widgets/progress_header.dart)):

```dart
AnimatedContainer(
  duration: duration,                         // 350 ms
  curve: Motion.curve,                        // easeOutCubic: nhanh lúc đầu, chậm dần
  width: constraints.maxWidth * ratio,        // ratio đổi → thanh tự kéo dài
  decoration: BoxDecoration(
    color: allDone ? Colors.green : scheme.primary,   // xong hết → tự chuyển sang xanh lá
    borderRadius: BorderRadius.circular(6),
  ),
)
```

**Các implicit widget khác dùng trong dự án:**

| Widget | Thuộc tính tự animate | Dùng ở đâu |
|---|---|---|
| `AnimatedContainer` | kích thước, màu, viền, padding… | Thanh tiến độ; nền và viền thẻ công việc |
| `AnimatedOpacity` | độ trong suốt | Thông báo "Chưa có công việc nào" |
| `AnimatedScale` | tỉ lệ phóng to/thu nhỏ | Icon ✔ phóng to khi hoàn thành |
| `AnimatedDefaultTextStyle` | màu chữ, gạch ngang | Tiêu đề bị gạch khi hoàn thành |
| `AnimatedSwitcher` | thay widget con (khi `key` đổi) | Con số `x/y` trong thanh tiến độ |
| `AnimatedCrossFade` | chuyển giữa 2 widget | Chip "Đang thực hiện" ↔ "Đã hoàn thành" |
| `TweenAnimationBuilder` | giá trị bất kỳ qua `Tween` | Thẻ thông tin phóng nhẹ khi mở trang chi tiết |

**Các transition cơ bản:** `FadeTransition` (mờ dần), `SlideTransition` (trượt), `ScaleTransition` (phóng),
`SizeTransition` (co giãn kích thước). Các widget này **nhận một `Animation<double>` có sẵn** rồi áp vào widget con.
Chúng là "đầu ra" của animation, được dùng trong `AnimatedList`, `AnimatedSwitcher` và khi chuyển trang.

```dart
// home_screen.dart – item mới chèn vào danh sách
SizeTransition(
  sizeFactor: curved,                 // chiều cao giãn từ 0 → đầy đủ
  child: FadeTransition(
    opacity: curved,                  // đồng thời hiện dần từ 0 → 1
    child: TaskTile(...),
  ),
)
```

### 3.2. AnimationController và quản lý tài nguyên

**Khái niệm:** `AnimationController` là một `Animation<double>` đặc biệt. Ở mỗi frame (≈60–120 lần/giây),
nó sinh ra một giá trị từ **0.0 → 1.0** trong khoảng `duration`. Có thể ra lệnh cho nó:

| Lệnh | Ý nghĩa |
|---|---|
| `forward()` | chạy 0 → 1 |
| `forward(from: 0)` | chạy lại từ đầu (dùng cho hiệu ứng lắc) |
| `reverse()` | chạy ngược 1 → 0 |
| `repeat()` | lặp liên tục |
| `stop()` | dừng tại chỗ |

**Các thành phần thường đi kèm:**

- **Tween**: ánh xạ 0..1 sang giá trị thật, ví dụ `Tween(begin: Offset(0, 0.08), end: Offset.zero)`.
- **Curve**: đường cong tốc độ, ví dụ `Curves.easeOutCubic`, `Curves.easeOutBack` (nảy nhẹ).
- **AnimatedBuilder**: rebuild **chỉ phần giao diện cần chuyển động** mỗi khi controller đổi giá trị.

**Vì sao phải quản lý tài nguyên?** Mỗi controller giữ một **Ticker**, tức một bộ đếm được gọi ở mọi frame.
Nếu không giải phóng, Ticker vẫn chạy sau khi widget đã bị hủy, dẫn đến:
- rò rỉ bộ nhớ, tốn CPU và pin;
- lỗi khi chạy: *"… was disposed with an active Ticker"*.

**Vòng đời đúng của AnimationController:**

```
initState()  ──►  tạo controller (vsync: this)
     │
build()      ──►  AnimatedBuilder lắng nghe controller, vẽ theo giá trị hiện tại
     │
sự kiện      ──►  controller.forward(from: 0)
     │
dispose()    ──►  controller.dispose()   ← BẮT BUỘC
```

**5 nguyên tắc** (áp dụng trong [shake_widget.dart](lib/widgets/shake_widget.dart)):

1. **Tạo controller trong `initState`**, không tạo trong `build`, vì `build` chạy lại rất nhiều lần.
2. **Truyền `vsync: this`** kèm mixin `SingleTickerProviderStateMixin` (1 controller) hoặc
   `TickerProviderStateMixin` (nhiều controller). Khi đó Ticker **tự tạm dừng khi widget không hiển thị**.
3. **Luôn gọi `dispose()`** cho controller trong `dispose()` của State.
4. **Giảm số lần rebuild:** truyền phần tĩnh vào tham số `child` của `AnimatedBuilder`, để nó không bị dựng lại ở mỗi frame.
5. **Ưu tiên widget tự quản lý controller** như implicit animation, `PageRouteBuilder`, `Dismissible`, `Hero`
   khi không cần điều khiển chi tiết.

```dart
class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {             // (2) cung cấp vsync
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(                // (1) tạo trong initState
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  void shake() {
    if (Motion.reduced(context)) return;              // tôn trọng "giảm chuyển động"
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();                            // (3) giải phóng tài nguyên
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,                            // (4) phần tĩnh không bị rebuild
      builder: (context, child) {
        final t = _controller.value;                  // 0 → 1
        final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);  // dao động, biên độ giảm dần
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
```

Các controller khác cũng phải được giải phóng: `TextEditingController` trong `HomeScreen` được `dispose()` theo cùng nguyên tắc.

**Các lỗi thường gặp:**

| Lỗi | Hậu quả | Cách tránh |
|---|---|---|
| Tạo controller trong `build` | Mỗi lần rebuild sinh thêm controller mới, gây rò rỉ | Tạo trong `initState` |
| Quên `dispose()` | Ticker vẫn chạy, báo lỗi "active Ticker" | Luôn `dispose()` |
| Không dùng `vsync` | Animation chạy cả khi màn hình bị che | `vsync: this` + mixin |
| `setState` trong listener để vẽ lại cả màn hình | Giật, tốn hiệu năng | Dùng `AnimatedBuilder` với `child` |

### 3.3. Gesture, thời điểm dùng animation và trải nghiệm người dùng

**Gesture** là cử chỉ của người dùng trên màn hình. Flutter cung cấp:
- `GestureDetector`: nhận mọi loại cử chỉ, không có hiệu ứng hình ảnh;
- `InkWell`: giống trên nhưng có hiệu ứng gợn sóng (ripple) theo Material Design;
- widget dựng sẵn như `Dismissible` (vuốt để xóa) hay `Draggable` (kéo thả).

**Gesture dùng trong dự án:**

| Cử chỉ | Widget | Hành động | Animation phản hồi |
|---|---|---|---|
| **Chạm** (tap) | `InkWell.onTap` | Đánh dấu hoàn thành / bỏ đánh dấu | Ripple, thẻ đổi màu, icon phóng to, chữ gạch ngang |
| **Nhấn giữ** (long press) | `InkWell.onLongPress` | Mở chi tiết | Chuyển trang Fade + Slide, tiêu đề bay sang (Hero) |
| **Vuốt trái** (swipe) | `Dismissible` | Xóa công việc | Thẻ trượt theo ngón tay, nền đỏ hiện ra, danh sách co lại |

**Khi nào NÊN dùng animation?**

| Mục đích | Ví dụ trong dự án |
|---|---|
| **Phản hồi thao tác**: người dùng biết thao tác đã được nhận | Chạm → icon ✔ phóng to, thẻ đổi màu |
| **Giải thích thay đổi**: thấy rõ cái gì xuất hiện, biến mất | Item mới mọc ra; item bị xóa trượt đi |
| **Giữ ngữ cảnh khi chuyển màn hình** | Hero: tiêu đề bay từ danh sách sang trang chi tiết |
| **Báo lỗi nhẹ nhàng** | Lắc ô nhập thay vì hiện hộp thoại |
| **Thể hiện tiến trình** | Thanh tiến độ kéo dài dần |

**Khi nào KHÔNG nên?**
- Hiệu ứng chỉ để trang trí, kéo dài trên 500 ms, lặp vô hạn.
- Hiệu ứng bắt người dùng chờ xong mới bấm tiếp được.
- Quá nhiều thứ chuyển động cùng lúc, khiến người dùng không biết nhìn vào đâu.

**Thời lượng khuyến nghị** (theo hướng dẫn Material Design):

| Loại | Thời lượng | Trong dự án |
|---|---|---|
| Phản hồi nhỏ (icon, màu) | 100–200 ms | `Motion.fast` = 150 ms |
| Thay đổi thành phần (thẻ, danh sách) | 200–300 ms | `Motion.medium` = 250 ms |
| Chuyển màn hình, thay đổi lớn | 300–400 ms | `Motion.slow` = 350 ms |

**Tác động đến trải nghiệm người dùng:**
- ✅ Dùng đúng: app có cảm giác **nhanh, mượt, dễ hiểu**, người dùng tự tin thao tác.
- ❌ Dùng sai: app **chậm, rối, gây khó chịu**; với người nhạy cảm chuyển động còn có thể gây chóng mặt.
  Vì vậy app cần tôn trọng cài đặt *"Giảm chuyển động"* của hệ điều hành.

---

## 4. Các hiệu ứng trong chương trình

Tóm tắt 9 hiệu ứng:

| # | Hiệu ứng | Kích hoạt bằng | Kỹ thuật |
|---|---|---|---|
| 1 | Item mới mọc ra | Bấm **Thêm** | `AnimatedList` + `SizeTransition` + `FadeTransition` |
| 2 | Ô nhập bị lắc | Bấm **Thêm** khi ô trống | `AnimationController` + `AnimatedBuilder` |
| 3 | Thẻ chuyển trạng thái hoàn thành | **Chạm** công việc | `AnimatedContainer`, `AnimatedScale`, `AnimatedDefaultTextStyle` |
| 4 | Thanh tiến độ | Tự động khi số liệu đổi | `AnimatedContainer`, `AnimatedSwitcher` |
| 5 | Vuốt để xóa | **Vuốt trái** công việc | `Dismissible` |
| 6 | Hoàn tác | Bấm **HOÀN TÁC** | `AnimatedList.insertItem` |
| 7 | Chuyển sang trang chi tiết | **Nhấn giữ** công việc | `PageRouteBuilder` + `Hero` |
| 8 | Hiệu ứng trong trang chi tiết | Mở trang chi tiết | `AnimatedCrossFade`, `TweenAnimationBuilder` |
| 9 | Thông báo danh sách trống | Xóa hết công việc | `AnimatedOpacity` + `IgnorePointer` |

Chi tiết từng hiệu ứng:

### Hiệu ứng 1 – Item mới mọc ra
- **Kích hoạt:** nhập tên công việc, bấm **Thêm** hoặc nhấn Enter.
- **Diễn ra:** công việc mới xuất hiện ở đầu danh sách. Chiều cao giãn dần từ 0 và hiện dần từ trong suốt, trong 350 ms.
  Các item bên dưới bị đẩy xuống mượt, không nhảy.
- **Code:** [home_screen.dart](lib/screens/home_screen.dart), hàm `_addTask()` và `_buildAnimatedItem()`.
  ```dart
  _tasks.insert(0, Task(id: _nextId++, title: title));       // 1. cập nhật dữ liệu
  _listKey.currentState?.insertItem(0, duration: ...);       // 2. báo AnimatedList chạy hiệu ứng chèn
  ```

### Hiệu ứng 2 – Ô nhập bị lắc (AnimationController)
- **Kích hoạt:** bấm **Thêm** khi ô nhập đang trống.
- **Diễn ra:** ô nhập rung qua lại theo hình sin, biên độ giảm dần, trong 400 ms. Đây là cách báo lỗi không cần hộp thoại.
- **Code:** [shake_widget.dart](lib/widgets/shake_widget.dart). `HomeScreen` gọi hiệu ứng qua `GlobalKey`:
  ```dart
  if (title.isEmpty) {
    _shakeKey.currentState?.shake();
    return;
  }
  ```

### Hiệu ứng 3 – Thẻ chuyển trạng thái hoàn thành
- **Kích hoạt:** **chạm** vào một công việc. Chạm lần nữa để bỏ đánh dấu.
- **Diễn ra:** cùng lúc trong 250 ms: nền thẻ chuyển sang xanh nhạt, xuất hiện viền xanh,
  icon ○ đổi thành ✔ và phóng to (curve `easeOutBack` tạo độ nảy), chữ chuyển xám và bị gạch ngang.
- **Code:** [task_tile.dart](lib/widgets/task_tile.dart). Chỉ cần `setState(() => task.done = !task.done)`,
  các widget `Animated…` tự chạy hiệu ứng.

### Hiệu ứng 4 – Thanh tiến độ
- **Kích hoạt:** tự động mỗi khi thêm, xóa hoặc hoàn thành công việc.
- **Diễn ra:** thanh kéo dài hoặc co lại tới tỉ lệ mới, chuyển màu xanh lá khi xong hết.
  Con số `x/y` cũ mờ đi và số mới phóng to hiện ra.
- **Code:** [progress_header.dart](lib/widgets/progress_header.dart). `AnimatedSwitcher` nhận biết nội dung mới nhờ
  `key: ValueKey('$done/$total')`.

### Hiệu ứng 5 – Vuốt để xóa (Gesture)
- **Kích hoạt:** **vuốt trái** một công việc.
- **Diễn ra:** thẻ trượt theo ngón tay, nền đỏ có biểu tượng thùng rác hiện ra bên dưới.
  Vuốt đủ xa thì thẻ trượt hẳn ra ngoài và danh sách co lại. Vuốt chưa đủ xa thì thẻ bật về chỗ cũ.
- **Code:** [task_tile.dart](lib/widgets/task_tile.dart), widget `Dismissible`.

### Hiệu ứng 6 – Hoàn tác
- **Kích hoạt:** sau khi xóa, bấm **HOÀN TÁC** trên thanh SnackBar ở cuối màn hình.
- **Diễn ra:** công việc mọc lại đúng vị trí cũ, dùng chung hiệu ứng với hiệu ứng 1.
- **Code:** [home_screen.dart](lib/screens/home_screen.dart), hàm `_delete()`.

### Hiệu ứng 7 – Chuyển sang trang chi tiết
- **Kích hoạt:** **nhấn giữ** một công việc.
- **Diễn ra:** trang chi tiết hiện dần và trượt nhẹ từ dưới lên. Đồng thời, tiêu đề công việc **bay** từ vị trí
  trong danh sách lên đầu trang chi tiết (Hero). Khi bấm Back, hiệu ứng chạy ngược lại.
- **Code:** [fade_slide_route.dart](lib/utils/fade_slide_route.dart) và `Hero(tag: 'task-${task.id}')`
  ở cả [task_tile.dart](lib/widgets/task_tile.dart) lẫn [task_detail_screen.dart](lib/screens/task_detail_screen.dart).
  Hai Hero phải có **cùng `tag`**.

### Hiệu ứng 8 – Hiệu ứng trong trang chi tiết
- **Kích hoạt:** tự chạy khi mở trang chi tiết.
- **Diễn ra:** thẻ thông tin phóng từ 90% lên 100% và nảy nhẹ (`TweenAnimationBuilder`).
  Chip trạng thái dùng `AnimatedCrossFade` để chuyển mượt giữa "Đang thực hiện" và "Đã hoàn thành".
- **Code:** [task_detail_screen.dart](lib/screens/task_detail_screen.dart).

### Hiệu ứng 9 – Thông báo danh sách trống
- **Kích hoạt:** xóa hết toàn bộ công việc.
- **Diễn ra:** dòng "🎉 Chưa có công việc nào" hiện dần ở giữa màn hình, và mờ đi khi thêm công việc mới.
- **Code:** [home_screen.dart](lib/screens/home_screen.dart). Dòng thông báo được bọc trong `IgnorePointer` để không chặn chạm.

---

## 5. Bảo đảm chuyển động không cản trở thao tác

| # | Biện pháp | Cách làm trong code | Lợi ích |
|---|---|---|---|
| 1 | **Thời lượng ngắn, thống nhất** | Mọi duration lấy từ [motion.dart](lib/utils/motion.dart): 150 / 250 / 350 ms | Người dùng không phải chờ |
| 2 | **Không khóa input khi đang animate** | Không bọc nút hay danh sách trong `AbsorbPointer`/`IgnorePointer` | Có thể bấm tiếp ngay khi hiệu ứng chưa xong |
| 3 | **Animation ngắt được giữa chừng** | Implicit animation tự đổi hướng từ vị trí hiện tại | Chạm nhanh liên tục không bị kẹt hay giật |
| 4 | **Dữ liệu cập nhật trước, animation chỉ là hình thức** | `task.done` và danh sách đổi ngay, rồi mới chạy hiệu ứng | Logic không phụ thuộc animation; test vẫn đúng |
| 5 | **Lớp trang trí không chặn chạm** | Thông báo "danh sách trống" bọc `IgnorePointer` | Không "ăn" mất cú chạm vào danh sách |
| 6 | **Thao tác xóa có đường lui** | SnackBar có nút **HOÀN TÁC** | Lỡ vuốt nhầm vẫn khôi phục được |
| 7 | **Gesture không xung đột** | Chạm / nhấn giữ / vuốt ngang tách biệt; vuốt ngang không đụng cuộn dọc | Không kích hoạt nhầm; có dòng hướng dẫn trên danh sách |
| 8 | **Báo lỗi không chặn màn hình** | Lắc ô nhập thay vì `AlertDialog` | Người dùng gõ tiếp được ngay |
| 9 | **Tôn trọng "Giảm chuyển động"** | `Motion.of(context, d)` trả về `Duration.zero` khi `MediaQuery.disableAnimations` bật; `shake()` bỏ qua hiệu ứng | Thân thiện với người nhạy cảm chuyển động |
| 10 | **Hiệu năng tốt** | `AnimatedBuilder` + `child`; controller có `vsync` và được `dispose` | Không giật, không rò rỉ bộ nhớ |

Đoạn code trung tâm của biện pháp 1 và 9:

```dart
class Motion {
  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow   = Duration(milliseconds: 350);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;     // tắt animation nếu người dùng yêu cầu
}
```

---

## 6. Kịch bản demo

Thời lượng khoảng 3 phút.

| Bước | Thao tác | Điều cần chỉ ra |
|---|---|---|
| 1 | Mở app | Thanh tiến độ `0/3`, dòng hướng dẫn cử chỉ |
| 2 | Bấm **Thêm** khi ô trống | Ô nhập **lắc**: đây là `AnimationController`, đã được `dispose` đúng cách |
| 3 | Nhập "Viết báo cáo" → **Thêm** | Item **mọc ra** ở đầu danh sách, số đếm đổi `0/4` |
| 4 | **Chạm** vài công việc | Thẻ chuyển xanh, chữ gạch ngang, icon nảy, thanh tiến độ kéo dài |
| 5 | **Chạm liên tục thật nhanh** vào một công việc | Hiệu ứng đổi hướng ngay, **không chặn thao tác** |
| 6 | **Vuốt trái** một công việc | Thẻ trượt đi, nền đỏ, danh sách co lại |
| 7 | Bấm **HOÀN TÁC** | Công việc mọc lại đúng chỗ |
| 8 | **Nhấn giữ** một công việc | Chuyển trang Fade + Slide, tiêu đề **bay** sang (Hero) |
| 9 | Bấm Back | Hiệu ứng chạy ngược |
| 10 | Hoàn thành tất cả | Thanh tiến độ chuyển **xanh lá** |
| 11 | *(Tùy chọn)* Bật "Xóa hiệu ứng động" / "Remove animations" trong cài đặt trợ năng của máy, mở lại app | Mọi hiệu ứng tắt, app vẫn hoạt động bình thường |

---

## 7. Câu hỏi thường gặp

**Hỏi: Khác nhau giữa `AnimatedContainer` và `AnimationController`?**
Đáp: `AnimatedContainer` là implicit animation: chỉ cần đổi giá trị, Flutter tự chạy hiệu ứng và tự quản lý controller.
`AnimationController` là explicit animation: lập trình viên tự tạo, ra lệnh chạy/dừng/lặp và phải tự `dispose`.

**Hỏi: Tại sao hiệu ứng lắc phải dùng `AnimationController` mà không dùng implicit?**
Đáp: hiệu ứng lắc cần **chạy lại từ đầu mỗi lần bấm** (`forward(from: 0)`), dù giá trị trạng thái không đổi.
Implicit animation chỉ chạy khi giá trị đích thay đổi nên không làm được việc này.

**Hỏi: `vsync: this` để làm gì?**
Đáp: nó gắn controller với một `TickerProvider`, để Ticker chỉ chạy khi widget đang hiển thị trên màn hình.
Cách này tiết kiệm CPU và pin.

**Hỏi: Nếu quên `dispose()` thì sao?**
Đáp: Ticker vẫn chạy sau khi widget bị hủy, gây rò rỉ bộ nhớ, và Flutter báo lỗi *"was disposed with an active Ticker"*.

**Hỏi: Tại sao khi xóa lại dùng `removeItem(..., duration: Duration.zero)`?**
Đáp: `Dismissible` đã tự chạy hiệu ứng trượt và co lại. Nếu `AnimatedList` chạy thêm một hiệu ứng nữa thì sẽ bị lặp,
nên chỉ cần gỡ item ngay lập tức.

**Hỏi: Làm sao chứng minh animation không chặn thao tác?**
Đáp: chạm liên tục thật nhanh vào một công việc: trạng thái đổi đúng theo từng lần chạm, hiệu ứng đảo chiều ngay.
Ngoài ra, test tự động trong `test/widget_test.dart` vẫn xác nhận dữ liệu đúng.

---

## 8. Kết luận

- **Implicit animation** (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`…) phù hợp với đa số hiệu ứng
  thay đổi trạng thái: code ngắn, an toàn, tự quản lý tài nguyên.
- **AnimationController** dùng khi cần điều khiển chủ động, và **bắt buộc** đúng vòng đời:
  tạo ở `initState`, dùng `vsync`, giải phóng ở `dispose`.
- **Gesture + animation** giúp người dùng nhận phản hồi tức thì và hiểu điều gì vừa xảy ra.
- Chuyển động tốt là chuyển động **ngắn, có mục đích, ngắt được và không bao giờ bắt người dùng phải chờ**.
