# Agribank Alert (Hệ thống Chuyển tiếp & Đọc Thông báo Tiền vào Agribank)

> Ứng dụng Android xây dựng bằng **Flutter**, **Kotlin Native** và **Firebase Backend** giúp chuyển tiếp thông báo biến động số dư nhận tiền từ ứng dụng Agribank trên **Điện thoại A** sang **Điện thoại B**, tự động đọc to số tiền bằng giọng nói tiếng Việt tự nhiên và lưu lịch sử giao dịch.

---

## 1. Tính năng nổi bật

* **Bắt thông báo thông minh (Kotlin `NotificationListenerService`)**:
  * Tự động quét thông báo từ ứng dụng Agribank (`com.vnpay.Agribank3g`).
  * Có khả năng bắt thông báo ngay cả khi ứng dụng bị tắt hoặc khóa màn hình nhờ hàng đợi nền SharedPreferences.
  * Hỗ trợ chế độ Debug bắt tất cả thông báo hoặc ứng dụng SMS, OTT.
* **Bộ phân tích cú pháp chuẩn xác (Notification Parser)**:
  * Nhận diện chính xác giao dịch nhận tiền (**Credit / Tiền vào**): `+`, `nhận tiền`, `cộng tiền`, `vào tài khoản`...
  * Tự động loại bỏ và chặn giao dịch trừ tiền (**Debit / Tiền ra**) như rút tiền ATM, thanh toán hoá đơn.
  * Tự động lọc bỏ tin nhắn rác, quảng cáo, mã OTP và thông báo bảo mật.
  * Trích xuất số tiền, số tài khoản, nội dung chuyển khoản và mã giao dịch.
* **Đọc số tiền bằng giọng nói tiếng Việt (Vietnamese TTS)**:
  * Thuật toán chuyển đổi số thành chữ tiếng Việt chuẩn ngữ pháp:
    * `500,000` -> *"năm trăm nghìn đồng"*
    * `1,250,000` -> *"một triệu hai trăm năm mươi nghìn đồng"*
    * `10,000,000` -> *"mười triệu đồng"*
  * Tương thích với tất cả các engine Text-to-Speech (Google TTS, Samsung TTS...).
  * Tùy chỉnh tốc độ đọc, âm lượng, tiền tố thông báo ("Bạn vừa nhận...", "Tài khoản vừa cộng...").
* **Cơ chế chống trùng lặp 2 lớp (Deduplication)**:
  * Lớp 1 (Local): Băm dữ liệu (Amount + Account + RefCode + Time bucket) lưu vào bộ nhớ cache để ngăn đọc lặp khi ngân hàng bắn nhiều thông báo.
  * Lớp 2 (Cloud): Firebase Functions & Firestore xác thực `eventId` duy nhất trước khi chuyển tiếp sang thiết bị B.
* **Ghép cặp thiết bị nhanh bằng Mã 6 ký tự (Pair Code)**:
  * Tạo mã ghép nối ngẫu nhiên (dạng `AG-XXXX`) có thời hạn.
  * Ghép nối 2 máy nhanh chóng mà không cần đăng nhập phức tạp.
* **Phòng kiểm thử tích hợp (Test Lab)**:
  * Kịch bản mẫu OTT Agribank Plus (+500K).
  * Kịch bản mẫu tin nhắn SMS (+1.25M).
  * Kịch bản test từ chối rút tiền (-200K) và mã OTP.
  * Tự nhập văn bản bất kỳ để kiểm tra bộ phân tích và loa phát.
  * Bắn thông báo Android thật vào thanh thông báo để kiểm thử Native Listener.

---

## 2. Kiến trúc hệ thống

```
┌──────────────────────────────────────────────┐
│           ĐIỆN THOẠI A (Máy gửi)             │
│                                              │
│       Ứng dụng Agribank (E-Mobile)           │
│                      │                       │
│                      ▼                       │
│  AgribankNotificationListenerService.kt      │
│                      │                       │
│                      ▼                       │
│       NotificationParser (Dart)              │
│                      │                       │
│                      ▼                       │
│   Gửi sự kiện HTTPS / Cloud Functions        │
└──────────────────────┬───────────────────────┘
                       │ Internet
                       ▼
┌──────────────────────────────────────────────┐
│               FIREBASE CLOUD                 │
│                                              │
│  • Cloud Functions (forwardAlert, pairDevice)│
│  • Cloud Firestore (pair_codes, transactions)│
│  • Firebase Cloud Messaging (FCM High-Pri)   │
└──────────────────────┬───────────────────────┘
                       │ Internet
                       ▼
┌──────────────────────────────────────────────┐
│          ĐIỆN THOẠI B (Máy nhận & Loa)       │
│                                              │
│             Nhận sự kiện FCM                 │
│                      │                       │
│                      ▼                       │
│       Kiểm tra chống trùng lặp               │
│                      │                       │
│                      ▼                       │
│       Hiển thị thông báo nổi (Popup)         │
│                      │                       │
│                      ▼                       │
│      Đọc to số tiền bằng giọng nói (TTS)     │
│                      │                       │
│                      ▼                       │
│            Lưu lịch sử giao dịch             │
└──────────────────────────────────────────────┘
```

---

## 3. Cấu trúc thư mục dự án

```
argibank-alert/
├── android/                             # Cấu hình Android Native & Kotlin
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml          # Khai báo NotificationListenerService, quyền hạn
│   │   └── kotlin/com/agribankalert/agribank_alert/
│   │       ├── MainActivity.kt          # Platform channels (MethodChannel & EventChannel)
│   │       ├── AgribankNotificationListenerService.kt # Lắng nghe thông báo hệ thống Android
│   │       └── NotificationReceiverBridge.kt          # Hàng đợi lưu thông báo khi app tắt
├── lib/
│   ├── main.dart                        # Điểm khởi chạy ứng dụng & Navigation đa màn hình
│   ├── core/
│   │   ├── constants/app_colors.dart    # Bảng màu chủ đạo nhận diện Agribank
│   │   ├── models/
│   │   │   ├── device_role.dart         # Vai trò: Máy A, Máy B, Độc lập
│   │   │   ├── pairing_info.dart        # Thông tin ghép cặp thiết bị
│   │   │   └── transaction_alert.dart   # Model chuẩn hoá dữ liệu giao dịch
│   │   └── services/
│   │       ├── notification_listener_service.dart # Giao tiếp kênh Native
│   │       ├── notification_parser.dart           # Bộ lọc & phân tích thông báo Agribank
│   │       ├── vietnamese_number_to_words.dart    # Đọc số tiền ra chữ tiếng Việt
│   │       ├── tts_service.dart                   # Điều khiển phát âm thanh TTS
│   │       ├── local_notification_service.dart    # Hiển thị thông báo nổi trên Android
│   │       ├── relay_service.dart                 # Chuyển tiếp sự kiện qua mạng
│   │       └── storage_service.dart               # Lưu trữ dữ liệu SharedPreferences
│   ├── providers/
│   │   ├── alert_provider.dart          # Quản lý sự kiện, thống kê trong ngày, lịch sử
│   │   ├── pairing_provider.dart        # Quản lý mã ghép nối & kết nối máy đối tác
│   │   └── settings_provider.dart       # Quản lý vai trò, cấu hình âm thanh, package filter
│   └── ui/
│       ├── screens/
│       │   ├── home_screen.dart         # Trang chủ thống kê & trạng thái hệ thống
│       │   ├── history_screen.dart      # Lịch sử giao dịch & tìm kiếm
│       │   ├── pairing_screen.dart      # Màn hình ghép cặp thiết bị A & B
│       │   ├── test_lab_screen.dart     # Phòng kiểm thử & chẩn đoán
│       │   └── settings_screen.dart     # Cài đặt giọng đọc, package, quyền hạn
│       └── widgets/
│           ├── status_indicator_card.dart
│           └── transaction_card.dart
├── test/
│   └── widget_test.dart                 # Bộ Unit Test tự động cho Parser & Bộ đọc số tiền
├── functions/                           # Mã nguồn Backend Firebase Cloud Functions
│   ├── package.json
│   ├── index.js                         # Functions: forwardAlert, pairDevice, registerFcmToken
│   └── README.md                        # Hướng dẫn deploy Firebase
├── firebase.json                        # Cấu hình Firebase Hosting & Functions
├── firestore.rules                      # Quy tắc bảo mật dữ liệu Firestore
└── firestore.indexes.json               # Đánh chỉ mục cơ sở dữ liệu
```

---

## 4. Hướng dẫn chạy và sử dụng

### 4.1. Cài đặt các gói phụ thuộc
Trong thư mục gốc dự án:
```bash
flutter pub get
```

### 4.2. Chạy kiểm thử tự động
```bash
flutter test
```
Toàn bộ các bài kiểm thử đơn vị cho thuật toán đọc số tiếng Việt và bộ phân tích cú pháp sẽ chạy và xác nhận tính hợp lệ.

### 4.3. Chạy ứng dụng trên thiết bị Android
Cắm thiết bị Android hoặc bật máy ảo Android Emulator và chạy:
```bash
flutter run
```

---

## 5. Cấu hình quyền trên điện thoại thực tế

Để ứng dụng đọc được biến động số dư khi giao dịch phát sinh, cần bật 2 quyền sau:

1. **Quyền truy cập thông báo (Notification Access)**:
   * Trên ứng dụng, tại màn hình **Trang chủ** hoặc **Cài đặt**, bấm nút **"Cấp quyền"**.
   * Hệ thống sẽ mở trang *Truy cập thông báo* của Android. Tìm **Agribank Alert** và gạt công tắc sang **BẬT**.
2. **Bỏ qua tối ưu hóa pin (Battery Optimization)**:
   * Bấm nút **"Bỏ qua tối ưu pin"** để cho phép ứng dụng duy trì dịch vụ chạy ngầm ngay cả khi khóa màn hình hoặc máy bật chế độ tiết kiệm năng lượng.

---

## 6. Hướng dẫn ghép cặp 2 điện thoại

1. Cài đặt **Agribank Alert** trên cả **Điện thoại A** (máy cài ứng dụng Agribank) và **Điện thoại B** (máy đặt ở quầy thu ngân để phát loa).
2. Trên **Điện thoại A**:
   * Vào tab **Cài đặt** -> chọn vai trò **"Điện thoại A (Máy gửi)"**.
   * Vào tab **Ghép cặp** -> sao chép hoặc ghi nhớ **Mã ghép nối** (ví dụ: `AG-5832`).
3. Trên **Điện thoại B**:
   * Vào tab **Cài đặt** -> chọn vai trò **"Điện thoại B (Máy nhận & Loa)"**.
   * Vào tab **Ghép cặp** -> nhập mã `AG-5832` vào ô **"Kết Nối Đến Máy Đối Tác"** -> Bấm **"Kết Nối Thiết Bị"**.
4. Khi trạng thái hiển thị **"ĐÃ KẾT NỐI VỚI THIẾT BỊ"**, hệ thống đã sẵn sàng hoạt động!

---

## 7. An toàn thông tin & Bảo mật

* Ứng dụng **hoàn toàn không** yêu cầu hoặc lưu trữ mật khẩu đăng nhập Agribank.
* **Không** can thiệp vào giao dịch ngân hàng hay yêu cầu mã OTP.
* Toàn bộ việc xử lý số tiền chỉ dựa trên thông báo nổi công khai do Android cung cấp.
* Mã ghép nối là ngẫu nhiên và tự động hết hạn để bảo vệ quyền riêng tư.
