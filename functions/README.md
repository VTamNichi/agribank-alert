# Agribank Alert - Firebase Backend

Thư mục này chứa toàn bộ mã nguồn Backend cho hệ thống chuyển tiếp thông báo **Agribank Alert** sử dụng **Firebase Cloud Functions**, **Cloud Firestore** và **Firebase Cloud Messaging (FCM)**.

---

## 1. Các Cloud Functions chính

| Tên Function | Phương thức | Mô tả |
| :--- | :--- | :--- |
| `generatePairCode` | POST | Tạo mã ghép nối tạm thời (dạng `AG-XXXX`) có thời hạn 10 phút |
| `pairDevice` | POST | Ghép cặp 2 thiết bị Android với nhau thông qua mã ghép nối |
| `registerFcmToken` | POST | Lưu token FCM của thiết bị B để nhận thông báo đẩy |
| `forwardAlert` | POST | Chuyển tiếp giao dịch nhận tiền từ Điện thoại A sang Điện thoại B qua FCM, đồng thời chống trùng lặp sự kiện |

---

## 2. Hướng dẫn cài đặt & Deploy

### Bước 1: Đăng nhập Firebase CLI
```bash
firebase login
```

### Bước 2: Khởi tạo/chọn Firebase Project
```bash
firebase use --add
# Chọn Firebase project của bạn
```

### Bước 3: Cài đặt thư viện Functions
```bash
cd functions
npm install
```

### Bước 4: Chạy thử nghiệm trên Firebase Emulator (Tùy chọn)
```bash
npm run serve
```

### Bước 5: Triển khai lên Firebase Cloud
```bash
firebase deploy --only functions,firestore
```

Sau khi deploy thành công, Firebase sẽ cung cấp URL cho các functions (ví dụ: `https://asia-southeast1-<project-id>.cloudfunctions.net/`). Bạn hãy dán URL này vào mục **Cài đặt -> Cấu hình Máy chủ** trên ứng dụng Agribank Alert.
