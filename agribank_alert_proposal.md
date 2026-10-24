# Ý TƯỞNG DỰ ÁN: AGRIBANK ALERT

* **Phiên bản:** 1.0
* **Ngày:** 18/10/2026
* **Nền tảng:** Android
* **Công nghệ chính:** Flutter, Kotlin, Firebase

---

## 1. Tổng quan dự án

### 1.1. Tên dự án
**Agribank Alert** — Ứng dụng chuyển tiếp thông báo nhận tiền giữa hai điện thoại Android.

### 1.2. Mục tiêu
Xây dựng một ứng dụng cho phép người dùng nhận thông báo biến động số dư từ ứng dụng Agribank trên điện thoại A, sau đó chuyển thông tin giao dịch qua Internet đến điện thoại B.

**Điện thoại B có thể:**
* Hiển thị thông báo khi phát hiện giao dịch nhận tiền.
* Đọc số tiền nhận được bằng giọng nói tiếng Việt.
* Phát âm báo tùy theo cài đặt.
* Lưu lịch sử các thông báo đã nhận.
* Hoạt động khi hai điện thoại ở hai địa điểm khác nhau, miễn là có kết nối Internet.

> **Lưu ý:** Ứng dụng chỉ hỗ trợ thông báo giao dịch, không thực hiện chuyển tiền và không thay thế ứng dụng ngân hàng.

---

## 2. Phạm vi sử dụng

* **Điện thoại A:** Android, đã cài ứng dụng Agribank.
* **Điện thoại B:** Android, cài Agribank Alert.
* **Kết nối:** Internet qua Wi-Fi hoặc dữ liệu di động.
* **Ngôn ngữ đọc:** Tiếng Việt.
* **Dữ liệu đầu vào:** Thông báo do Android nhận từ ứng dụng Agribank.
* **Dữ liệu đầu ra:** Thông báo đẩy và nội dung đọc bằng giọng nói.
* **Giới hạn:** Ứng dụng phụ thuộc vào nội dung thông báo mà Agribank cung cấp, quyền `Notification Access` của Android và các giới hạn chạy nền của thiết bị. Không đảm bảo hoạt động nếu ngân hàng không gửi thông báo hoặc thông báo không có đủ thông tin.

---

## 3. Kiến trúc hệ thống

```
┌──────────────────────────────────┐
│          ĐIỆN THOẠI A            │
│                                  │
│       Ứng dụng Agribank          │
│                │                 │
│                ▼                 │
│  Android Notification Listener   │
│                │                 │
│                ▼                 │
│  Phân tích thông báo giao dịch   │
│                │                 │
│                ▼                 │
│     Gửi sự kiện lên Firebase     │
└────────────────┬─────────────────┘
                 │ Internet
                 ▼
┌──────────────────────────────────┐
│             FIREBASE             │
│                                  │
│     Firebase Authentication      │
│         Cloud Functions          │
│    Firebase Cloud Messaging      │
│        Firestore (tùy chọn)      │
│                                  │
│  Xác thực, chống trùng, chuyển   │
│   tiếp đến thiết bị đã ghép cặp  │
└────────────────┬─────────────────┘
                 │ Internet
                 ▼
┌──────────────────────────────────┐
│          ĐIỆN THOẠI B            │
│                                  │
│        Nhận thông báo FCM        │
│                │                 │
│                ▼                 │
│        Kiểm tra sự kiện          │
│                │                 │
│                ▼                 │
│        Hiển thị thông báo        │
│                │                 │
│                ▼                 │
│    Text-to-Speech tiếng Việt     │
└──────────────────────────────────┘
```

### 3.1. Các thành phần

| Thành phần | Công nghệ | Nhiệm vụ |
| :--- | :--- | :--- |
| **Giao diện** | Flutter | Cấu hình, ghép cặp, lịch sử |
| **Đọc thông báo** | Kotlin | Nhận thông báo Android (`NotificationListenerService`) |
| **Backend** | Firebase Cloud Functions | Xác thực và chuyển tiếp sự kiện |
| **Đẩy thông báo** | Firebase Cloud Messaging (FCM) | Gửi đến điện thoại B |
| **Cơ sở dữ liệu** | Cloud Firestore | Lưu thiết bị, ghép cặp và lịch sử |
| **Đọc số tiền** | Flutter TTS / Android TTS | Đọc bằng tiếng Việt |

---

## 4. Luồng hoạt động

1. Người dùng cài Agribank Alert trên điện thoại A và B.
2. Người dùng đăng ký hoặc ghép cặp hai thiết bị bằng mã ghép nối.
3. Điện thoại A được cấp quyền đọc thông báo Android (`Notification Access`).
4. Khi Agribank phát thông báo, dịch vụ Kotlin kiểm tra nguồn và nội dung thông báo.
5. Bộ phân tích xác định liệu thông báo có phải giao dịch nhận tiền hay không.
6. Nếu hợp lệ, điện thoại A gửi sự kiện đến Firebase qua kết nối HTTPS đã xác thực.
7. Backend kiểm tra quyền gửi, tính hợp lệ và dấu hiệu trùng lặp.
8. Firebase Cloud Messaging chuyển thông báo đến điện thoại B.
9. Điện thoại B hiển thị thông báo và đọc số tiền nếu người dùng đã bật tính năng.
10. Ứng dụng lưu lịch sử và đánh dấu sự kiện đã xử lý để hạn chế đọc lặp.

---

## 5. Yêu cầu chức năng

### 5.1. Trên điện thoại A
* Xin quyền `Notification Access`.
* Chỉ xử lý thông báo từ ứng dụng Agribank đã xác minh.
* Đọc tiêu đề và nội dung thông báo.
* Nhận diện giao dịch tiền vào.
* Bỏ qua thông báo không liên quan.
* Chuẩn hóa dữ liệu giao dịch.
* Chống gửi sự kiện trùng.
* Gửi dữ liệu qua HTTPS đến backend.
* Hiển thị trạng thái kết nối và trạng thái ghép cặp.
* Thông báo khi mất quyền đọc thông báo hoặc xảy ra lỗi.

### 5.2. Trên điện thoại B
* Đăng ký token FCM.
* Nhận thông báo từ Firebase.
* Hiển thị số tiền và thời gian.
* Đọc số tiền bằng tiếng Việt.
* Bật hoặc tắt tính năng đọc thành tiếng.
* Điều chỉnh âm lượng thông qua cài đặt âm thanh của thiết bị.
* Lưu lịch sử nhận thông báo.
* Chống đọc cùng một sự kiện nhiều lần.
* Hiển thị trạng thái kết nối.

### 5.3. Cài đặt chung
* Ghép cặp và hủy ghép cặp thiết bị.
* Đổi tên thiết bị.
* Bật/tắt thông báo.
* Bật/tắt giọng nói.
* Xem lịch sử sự kiện.
* Xóa lịch sử.
* Kiểm tra quyền và kết nối.
* Hỗ trợ thu hồi quyền truy cập thiết bị.

---

## 6. Mẫu dữ liệu giao dịch

Ví dụ dữ liệu đã được chuẩn hóa:

```json
{
  "eventId": "unique-event-id",
  "deviceId": "device-a",
  "amount": 500000,
  "currency": "VND",
  "direction": "credit",
  "occurredAt": "2026-10-18T12:30:00+07:00"
}
```

**Ý nghĩa:**
* `eventId`: Mã sự kiện duy nhất để chống trùng.
* `deviceId`: Định danh thiết bị gửi.
* `amount`: Số tiền giao dịch.
* `currency`: Đơn vị tiền tệ.
* `direction`: Loại giao dịch; `credit` nghĩa là tiền vào.
* `occurredAt`: Thời điểm giao dịch nếu xác định được.

> **Lưu ý:** Dữ liệu thực tế cần được phân tích từ thông báo. Không tự suy diễn số tiền hoặc loại giao dịch nếu nội dung không rõ ràng.

---

## 7. Quy tắc nhận diện giao dịch

Ứng dụng cần phân biệt:
* Tiền vào tài khoản.
* Tiền chuyển đi.
* Thông báo số dư.
* Thông báo quảng cáo.
* Thông báo đăng nhập hoặc bảo mật.
* Thông báo không đủ thông tin.

* Chỉ chuyển tiếp sự kiện khi bộ phân tích có đủ căn cứ xác định giao dịch nhận tiền.
* Nếu không xác định được loại giao dịch, hệ thống nên bỏ qua hoặc đưa vào trạng thái cần xác minh.
* Số tiền trong thông báo chỉ là dữ liệu đầu vào để thông báo lại, không phải bằng chứng độc lập về việc giao dịch đã được hạch toán thành công.

---

## 8. Thiết kế thông báo và giọng nói

**Ví dụ thông báo trên điện thoại B:**
* **Tiêu đề:** Agribank Alert — Nhận tiền
* **Nội dung:** Bạn vừa nhận 500.000 đồng.
* **Giọng nói:** *“Bạn vừa nhận năm trăm nghìn đồng.”*

**Các tùy chọn:**
* Chỉ hiển thị thông báo.
* Đọc số tiền bằng giọng nói.
* Phát âm báo và đọc số tiền.
* Tắt tiếng trong thời gian nghỉ.
* Chỉ đọc giao dịch thỏa điều kiện lọc.

> **Lưu ý:** Ứng dụng cần xử lý riêng trường hợp chạy nền, màn hình khóa và ứng dụng bị hệ điều hành dừng. Không mặc định rằng TTS luôn được phép phát âm thanh trong mọi trạng thái.

---

## 9. Bảo mật

* Không yêu cầu hoặc lưu mật khẩu Agribank.
* Không yêu cầu mã OTP ngân hàng.
* Không lưu thông tin đăng nhập ngân hàng.
* Không đưa khóa Firebase Admin vào ứng dụng.
* Xác thực thiết bị gửi và quyền nhận.
* Dùng Firebase Authentication và App Check phù hợp.
* Dùng mã ghép cặp ngẫu nhiên, có thời hạn và chỉ sử dụng một lần.
* Hạn chế dữ liệu được gửi qua Internet.
* Không chuyển tiếp toàn bộ thông báo của điện thoại.
* Không cho phép thiết bị tùy ý gửi thông báo đến thiết bị khác.
* Có chức năng hủy ghép cặp và thu hồi quyền.
* Hạn chế lưu lịch sử giao dịch và đặt thời hạn xóa dữ liệu.
* Không ghi nội dung giao dịch nhạy cảm vào log kỹ thuật không cần thiết.

---

## 10. Công nghệ và thư viện dự kiến

### Flutter
* `firebase_core`
* `firebase_messaging`
* `cloud_functions`
* `flutter_tts`
* `flutter_local_notifications`

### Android Native
* Kotlin
* `NotificationListenerService`
* Android Notification API
* Android Text-to-Speech (nếu cần xử lý âm thanh native)
* `WorkManager` cho các tác vụ nền phù hợp

### Backend
* Firebase Authentication
* Firebase Cloud Functions
* Firebase Cloud Messaging
* Cloud Firestore
* Firebase App Check

> **Lưu ý:** Các phiên bản thư viện cần được lựa chọn tương thích với Flutter SDK, Android Gradle Plugin và Android SDK tại thời điểm triển khai.

---

## 11. Kế hoạch phát triển

### Giai đoạn 1 — Kiểm chứng thông báo
1. Tạo project Flutter.
2. Cấu hình phần Android native bằng Kotlin.
3. Xin quyền `Notification Access`.
4. Xác minh package ID Agribank.
5. Thu thập mẫu thông báo thực tế đã che dữ liệu nhạy cảm.
6. Kiểm tra khả năng trích xuất nội dung.
* **Kết quả:** Xác định được ứng dụng có thể đọc và phân tích thông báo trên thiết bị thực tế.

### Giai đoạn 2 — Thử nghiệm chuyển tiếp
1. Tạo Firebase project.
2. Đăng ký thiết bị A và B.
3. Tạo cơ chế ghép cặp.
4. Gửi sự kiện thử nghiệm qua Cloud Functions.
5. Nhận thông báo FCM trên B.
* **Kết quả:** A gửi được sự kiện thử nghiệm, B nhận được qua Internet.

### Giai đoạn 3 — Đọc tiền bằng giọng nói
1. Chuẩn hóa số tiền.
2. Tích hợp TTS tiếng Việt.
3. Tạo cài đặt đọc thành tiếng.
4. Xử lý thông báo trùng.
5. Kiểm tra khi màn hình khóa và ứng dụng chạy nền.
* **Kết quả:** B đọc đúng số tiền trong các tình huống được hỗ trợ.

### Giai đoạn 4 — Hoàn thiện
1. Thêm lịch sử.
2. Thêm trạng thái kết nối.
3. Hoàn thiện xử lý lỗi.
4. Kiểm thử quyền riêng tư.
5. Kiểm thử mất mạng và khôi phục kết nối.
6. Kiểm thử trên nhiều dòng điện thoại Android.
* **Kết quả:** Bản thử nghiệm có thể dùng trong môi trường thực tế có kiểm soát.

---

## 12. Tiêu chí nghiệm thu

* A chỉ đọc thông báo từ đúng ứng dụng Agribank.
* A xác định đúng các mẫu thông báo nhận tiền đã kiểm thử.
* A không chuyển tiếp thông báo không liên quan.
* B nhận sự kiện khi hai máy ở hai mạng khác nhau.
* B đọc đúng số tiền và đơn vị tiền tệ.
* Sự kiện trùng không bị đọc nhiều lần trong các trường hợp đã kiểm thử.
* Quyền truy cập có thể thu hồi.
* Hệ thống không lưu mật khẩu hoặc OTP ngân hàng.
* Backend xác minh thiết bị gửi và quyền nhận.
* Có xử lý lỗi mạng, lỗi FCM và lỗi TTS.
* Đã kiểm thử chế độ chạy nền và tiết kiệm pin.

---

## 13. Rủi ro và giới hạn

* Agribank có thể thay đổi nội dung hoặc định dạng thông báo.
* Android có thể hạn chế việc nhận thông báo hoặc chạy nền.
* FCM không đảm bảo giao hàng tức thời trong mọi tình huống.
* TTS có thể không phát âm thanh khi hệ điều hành hạn chế ứng dụng.
* Nếu thông báo không chứa số tiền hoặc không phân biệt rõ tiền vào và tiền ra, ứng dụng không thể xác định chính xác chỉ từ dữ liệu đó.
* Ứng dụng không phải hệ thống đối soát ngân hàng chính thức.
* Cần kiểm thử trên đúng thiết bị và phiên bản Agribank đang sử dụng trước khi triển khai rộng rãi.

---

## 14. Tài liệu tham khảo

* **Flutter:** [https://docs.flutter.dev/](https://docs.flutter.dev/)
* **Firebase cho Flutter:** [https://firebase.google.com/docs/flutter/setup](https://firebase.google.com/docs/flutter/setup)
* **Firebase Cloud Messaging:** [https://firebase.google.com/docs/cloud-messaging/flutter/get-started](https://firebase.google.com/docs/cloud-messaging/flutter/get-started)
* **Firebase Cloud Functions:** [https://firebase.google.com/docs/functions](https://firebase.google.com/docs/functions)
* **Android NotificationListenerService:** [https://developer.android.com/reference/android/service/notification/NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService)
* **Android Text-to-Speech:** [https://developer.android.com/reference/android/speech/tts/TextToSpeech](https://developer.android.com/reference/android/speech/tts/TextToSpeech)

---

## Kết luận

Agribank Alert là ứng dụng hỗ trợ thông báo nhận tiền giữa hai thiết bị Android, sử dụng Flutter cho giao diện, Kotlin để đọc thông báo Android và Firebase để chuyển tiếp dữ liệu qua Internet.

Ưu tiên đầu tiên là **kiểm chứng khả năng đọc thông báo Agribank trên điện thoại A**. Sau khi xác nhận dữ liệu có thể được nhận diện đáng tin cậy, tiếp tục xây dựng cơ chế chuyển tiếp và đọc số tiền trên điện thoại B.