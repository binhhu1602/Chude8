# Animation Demo – Ứng dụng quản lý công việc có hiệu ứng chuyển động

Dự án Flutter minh họa **implicit animation**, **AnimationController (explicit animation)**, **gesture**
và cách đưa chuyển động vào chương trình mà **không làm cản trở thao tác của người dùng**.

Ứng dụng là một danh sách công việc (to-do) đơn giản: thêm việc, chạm để hoàn thành, vuốt để xóa,
nhấn giữ để xem chi tiết. Mỗi thao tác đi kèm một hiệu ứng phù hợp.

---

## 1. Cấu trúc dự án

```
lib/
├── main.dart                       # Điểm khởi chạy, MaterialApp + theme
├── models/
│   └── task.dart                   # Model Task (id, title, done)
├── utils/
│   ├── motion.dart                 # Thời lượng, curve chung + tôn trọng "giảm chuyển động"
│   └── fade_slide_route.dart       # Hiệu ứng chuyển trang tùy biến (Fade + Slide)
├── widgets/
│   ├── progress_header.dart        # Thanh tiến độ: AnimatedContainer + AnimatedSwitcher
│   ├── shake_widget.dart           # Hiệu ứng lắc: AnimationController + dispose
│   └── task_tile.dart              # Một dòng công việc: Gesture + implicit animation
└── screens/
    ├── home_screen.dart            # Màn hình chính: AnimatedList, ô nhập, SnackBar Undo
    └── task_detail_screen.dart     # Chi tiết: Hero, AnimatedCrossFade, TweenAnimationBuilder
test/
└── widget_test.dart                # Kiểm thử thêm việc + đánh dấu hoàn thành
```

### Chạy dự án

```bash
flutter pub get
flutter run          # chọn thiết bị: Android / Chrome / Windows
flutter test         # chạy kiểm thử
```

---

## 2. Cơ sở lý thuyết

### 2.1. Implicit animation (chuyển động ngầm định)

Implicit animation là các widget **tự chạy hiệu ứng khi giá trị thuộc tính thay đổi**.
Lập trình viên chỉ cần đổi giá trị (thường qua `setState`), Flutter sẽ nội suy từ giá trị cũ
sang giá trị mới trong khoảng `duration` với đường cong `curve`.

| Widget | Thuộc tính được animate | Dùng trong dự án |
|---|---|---|
| `AnimatedContainer` | width, height, color, padding, margin, decoration… | Thanh tiến độ, nền thẻ công việc |
| `AnimatedOpacity` | độ trong suốt | Thông báo "chưa có công việc" |
| `AnimatedScale` | tỉ lệ phóng | Icon check khi hoàn thành |
| `AnimatedDefaultTextStyle` | kiểu chữ | Gạch ngang tiêu đề khi xong |
| `AnimatedSwitcher` | thay widget con (dựa vào `key`) | Số "x/y" trong thanh tiến độ |
| `AnimatedCrossFade` | chuyển giữa 2 widget | Chip trạng thái ở màn chi tiết |
| `TweenAnimationBuilder` | giá trị bất kỳ qua `Tween` | Thẻ thông tin phóng nhẹ khi xuất hiện |

**Các transition cơ bản** (`FadeTransition`, `SlideTransition`, `ScaleTransition`, `SizeTransition`)
nhận một `Animation` có sẵn và áp vào widget con. Chúng được dùng trong `AnimatedList`,
`AnimatedSwitcher` và route chuyển trang.

Ví dụ (trích [progress_header.dart](lib/widgets/progress_header.dart)):

```dart
AnimatedContainer(
  duration: duration,
  curve: Motion.curve,
  width: constraints.maxWidth * ratio,          // ratio đổi -> thanh tự kéo dài
  decoration: BoxDecoration(
    color: allDone ? Colors.green : scheme.primary,  // màu cũng tự chuyển
  ),
)
```

**Ưu điểm:** code ngắn, không phải quản lý vòng đời, tự xử lý khi giá trị đổi giữa chừng
(animation đổi hướng mượt từ vị trí hiện tại).
**Hạn chế:** không điều khiển được lặp lại, đảo chiều, dừng giữa chừng → khi cần thì dùng explicit animation.

### 2.2. AnimationController và nguyên tắc quản lý tài nguyên

`AnimationController` là bộ điều khiển sinh giá trị từ 0.0 → 1.0 theo từng khung hình (frame).
Nó cho phép `forward()`, `reverse()`, `repeat()`, `stop()`, `forward(from: 0)`…

Mỗi controller giữ một **Ticker** (gắn với nhịp vẽ màn hình). Nếu quản lý sai sẽ gây
rò rỉ bộ nhớ, tốn CPU/pin, hoặc lỗi *"AnimationController.dispose() called more than once / Ticker was not disposed"*.

**Nguyên tắc** (áp dụng trong [shake_widget.dart](lib/widgets/shake_widget.dart)):

1. **Tạo trong `initState`**, không tạo trong `build` (vì `build` chạy lại nhiều lần).
2. **Dùng `vsync: this`** với `SingleTickerProviderStateMixin` (một controller) hoặc
   `TickerProviderStateMixin` (nhiều controller). Ticker sẽ tự tạm dừng khi widget không hiển thị.
3. **Luôn `dispose()`** controller trong `dispose()` của State.
4. **Chỉ rebuild phần chuyển động**: dùng `AnimatedBuilder` và truyền phần tĩnh qua tham số `child`.
5. Ưu tiên widget có sẵn tự quản lý controller (implicit animation, `PageRouteBuilder`,
   `Dismissible`, `Hero`) khi không cần điều khiển chi tiết.

```dart
class ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
  }

  void shake() => _controller.forward(from: 0);

  @override
  void dispose() {
    _controller.dispose();   // giải phóng tài nguyên
    super.dispose();
  }
  ...
}
```

Cùng nguyên tắc đó, `TextEditingController` trong `HomeScreen` cũng được `dispose()`.

### 2.3. Gesture, thời điểm dùng animation và trải nghiệm người dùng

**Gesture** là các thao tác chạm của người dùng. Flutter cung cấp `GestureDetector`, `InkWell`
(có hiệu ứng gợn sóng) và các widget dựng sẵn như `Dismissible` (vuốt để xóa).

| Gesture | Widget | Hành động |
|---|---|---|
| Tap (chạm) | `InkWell.onTap` | Đánh dấu hoàn thành |
| Long press (nhấn giữ) | `InkWell.onLongPress` | Mở màn hình chi tiết |
| Swipe (vuốt trái) | `Dismissible` | Xóa công việc |

**Khi nào nên dùng animation?**

- **Phản hồi thao tác** (feedback): người dùng chạm → thấy ngay kết quả (icon check phóng to, thẻ đổi màu).
- **Giải thích sự thay đổi trạng thái**: item mới mọc ra, item bị xóa trượt đi, thanh tiến độ kéo dài
  → người dùng hiểu chuyện gì vừa xảy ra thay vì giao diện "nhảy" đột ngột.
- **Giữ ngữ cảnh khi chuyển màn hình**: `Hero` cho tiêu đề "bay" sang trang chi tiết.
- **Báo lỗi nhẹ nhàng**: lắc ô nhập khi bỏ trống thay vì hiện hộp thoại chặn màn hình.

**Khi nào không nên?** Hiệu ứng trang trí kéo dài, lặp vô hạn, chặn nút bấm, hoặc khiến người dùng phải chờ.

**Tác động đến trải nghiệm:** animation tốt làm ứng dụng có cảm giác *nhanh, rõ ràng và có phản hồi*;
animation xấu (quá dài, quá nhiều, giật) làm ứng dụng *chậm và gây khó chịu*,
thậm chí gây chóng mặt với người nhạy cảm chuyển động.

---

## 3. Các hiệu ứng trong chương trình và cách kích hoạt

| # | Hiệu ứng | Loại | Cách kích hoạt | File |
|---|---|---|---|---|
| 1 | Item mới mọc ra (thu/giãn chiều cao + mờ dần) | `AnimatedList` + `SizeTransition` + `FadeTransition` | Nhập tên → bấm **Thêm** hoặc Enter | [home_screen.dart](lib/screens/home_screen.dart) |
| 2 | Ô nhập bị lắc | `AnimationController` + `AnimatedBuilder` | Bấm **Thêm** khi ô nhập trống | [shake_widget.dart](lib/widgets/shake_widget.dart) |
| 3 | Thẻ đổi màu, viền xanh, chữ gạch ngang, icon phóng to | `AnimatedContainer`, `AnimatedDefaultTextStyle`, `AnimatedScale` | **Chạm** vào công việc | [task_tile.dart](lib/widgets/task_tile.dart) |
| 4 | Thanh tiến độ kéo dài, đổi xanh khi xong hết; số đếm nảy lên | `AnimatedContainer`, `AnimatedSwitcher` | Tự chạy khi số việc xong/tổng thay đổi | [progress_header.dart](lib/widgets/progress_header.dart) |
| 5 | Vuốt để xóa, nền đỏ hiện ra | `Dismissible` (gesture) | **Vuốt trái** một công việc | [task_tile.dart](lib/widgets/task_tile.dart) |
| 6 | Hoàn tác: item mọc lại đúng vị trí | `AnimatedList.insertItem` | Bấm **HOÀN TÁC** trên SnackBar | [home_screen.dart](lib/screens/home_screen.dart) |
| 7 | Chuyển trang mờ dần + trượt lên; tiêu đề bay sang | `PageRouteBuilder` + `Hero` | **Nhấn giữ** một công việc | [fade_slide_route.dart](lib/utils/fade_slide_route.dart) |
| 8 | Chip trạng thái chuyển mượt, thẻ phóng nhẹ | `AnimatedCrossFade`, `TweenAnimationBuilder` | Mở màn chi tiết | [task_detail_screen.dart](lib/screens/task_detail_screen.dart) |
| 9 | Thông báo "chưa có công việc" hiện dần | `AnimatedOpacity` | Xóa hết công việc | [home_screen.dart](lib/screens/home_screen.dart) |

### Kịch bản demo gợi ý

1. Mở app → chỉ ra thanh tiến độ `0/3`.
2. Bấm **Thêm** khi ô trống → ô nhập **lắc** (AnimationController).
3. Nhập "Viết báo cáo" → **Thêm** → item mới mọc ra ở đầu danh sách, số đếm đổi `0/4`.
4. **Chạm** vài công việc → thẻ chuyển xanh, chữ gạch ngang, thanh tiến độ kéo dài.
   Chạm liên tục thật nhanh để chứng minh animation **không chặn** thao tác.
5. **Vuốt trái** một công việc → bị xóa → bấm **HOÀN TÁC** → mọc lại.
6. **Nhấn giữ** một công việc → tiêu đề bay sang màn chi tiết (Hero).
7. Hoàn thành tất cả → thanh tiến độ chuyển màu xanh lá.

---

## 4. Bảo đảm chuyển động không gây cản trở thao tác

1. **Thời lượng ngắn, thống nhất** – tất cả lấy từ [motion.dart](lib/utils/motion.dart):
   150 / 250 / 350 ms. Người dùng không bao giờ phải chờ animation chạy xong.
2. **Không khóa input trong lúc animate** – không có `IgnorePointer`/`AbsorbPointer` bao quanh
   nút bấm hay danh sách. Implicit animation tự **đổi hướng giữa chừng**: chạm 2 lần nhanh vào
   một công việc thì hiệu ứng đảo lại ngay từ vị trí hiện tại, không bị "kẹt".
3. **Lớp trang trí không chặn chạm** – thông báo "chưa có công việc" nằm đè lên danh sách nhưng được
   bọc `IgnorePointer`, nên không bao giờ "ăn" mất cú chạm.
4. **Trạng thái cập nhật ngay, animation chỉ là hình thức** – dữ liệu (`task.done`, danh sách)
   thay đổi tức thì; animation chỉ biểu diễn sự thay đổi đó. Test tự động vẫn kiểm tra đúng kết quả.
5. **Thao tác phá hủy có đường lui** – vuốt xóa luôn có nút **HOÀN TÁC**, tránh xóa nhầm do vuốt vô ý.
6. **Gesture rõ ràng, không xung đột** – chạm / nhấn giữ / vuốt ngang là 3 cử chỉ tách biệt;
   vuốt ngang (`Dismissible`) không xung đột với cuộn dọc của danh sách. Có dòng hướng dẫn ngay trên danh sách.
7. **Báo lỗi không chặn màn hình** – lắc ô nhập thay vì `AlertDialog`, người dùng gõ tiếp được ngay.
8. **Tôn trọng cài đặt trợ năng "Giảm chuyển động"** – `Motion.of(context, d)` trả về
   `Duration.zero` khi `MediaQuery.disableAnimations` bật; `ShakeWidget` cũng bỏ qua hiệu ứng lắc.
9. **Hiệu năng** – `AnimatedBuilder` chỉ rebuild phần chuyển động; controller có `vsync` và được `dispose`;
   dùng `Transform`/`Opacity` (rẻ) thay vì dựng lại cả cây widget.

---

## 5. Kết luận

- **Implicit animation** phù hợp cho đa số hiệu ứng thay đổi trạng thái: ngắn gọn, an toàn.
- **AnimationController** dùng khi cần điều khiển chủ động (chạy lại, lặp, đảo chiều) và **bắt buộc**
  tuân thủ vòng đời: tạo ở `initState`, `vsync`, `dispose`.
- Chuyển động nên **phục vụ thao tác** (phản hồi, giải thích, giữ ngữ cảnh), ngắn, có thể ngắt,
  và không bao giờ khiến người dùng phải chờ.
#   C h u d e 8  
 