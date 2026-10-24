# HƯỚNG DẪN CÀI ĐẶT MÔI TRƯỜNG DỰ ÁN AGRIBANK ALERT (PHẦN 1)

Tài liệu này tổng hợp chi tiết **3 bước cài đặt môi trường phát triển đầu tiên** cho dự án Agribank Alert (gồm Node.js, Firebase CLI, Flutter SDK, JDK 17 và Android Studio).

---

## BƯỚC 1: CÀI ĐẶT NODE.JS & FIREBASE CLI

Node.js và Firebase CLI cần thiết để quản lý, cấu hình và triển khai backend cho hệ thống (Cloud Functions, FCM, Firestore).

### 1.1. Cài đặt Node.js
1. Truy cập trang chủ: [nodejs.org](https://nodejs.org/).
2. Tải phiên bản **LTS** (phiên bản khuyến nghị cho đa số người dùng).
3. Chạy file installer (`.msi` hoặc `.pkg`) và nhấn **Next** để cài đặt theo mặc định.

### 1.2. Cài đặt Firebase CLI
1. Mở Terminal / Command Prompt (CMD) trên máy tính.
2. Cài đặt `firebase-tools` toàn cục qua lệnh:
   ```bash
   npm install -g firebase-tools
   ```
3. Kiểm tra cài đặt thành công:
   ```bash
   firebase --version
   ```

---

## BƯỚC 2: CÀI ĐẶT FLUTTER SDK & JAVA (JDK 17)

### 2.1. Cài đặt Flutter SDK
1. Truy cập trang chính thức: [docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install).
2. Chọn hệ điều hành tương ứng (Windows / macOS / Linux) và tải bản **Flutter SDK (.zip)**.
3. Giải nén vào thư mục không chứa khoảng trắng hay ký tự đặc biệt (Ví dụ: `C:\src\flutter` trên Windows).
4. **Thêm Flutter vào Biến Môi Trường (System Environment Variables - PATH):**
   * **Windows:** 
     1. Tìm kiếm *"Edit the system environment variables"* trong menu Start.
     2. Nhấn chọn **Environment Variables...**
     3. Tại mục **User variables**, chọn dòng `Path` -> Nhấn **Edit** -> Nhấn **New**.
     4. Dán đường dẫn thư mục `bin` của Flutter (VD: `C:\src\flutter\bin`).
     5. Nhấn **OK** để lưu lại toàn bộ.
   * **macOS / Linux:** Thêm `export PATH="$PATH:/path/to/flutter/bin"` vào file `~/.zshrc` hoặc `~/.bashrc`.

### 2.2. Cài đặt Java Development Kit (JDK 17)
1. Tải bộ cài JDK 17 tại [Adoptium (Eclipse Temurin)](https://adoptium.net/) hoặc Oracle JDK.
2. Chạy file installer và cài đặt theo các bước mặc định.
3. Cấu hình biến môi trường `JAVA_HOME` trỏ tới thư mục vừa cài đặt (nếu hệ thống yêu cầu).

---

## BƯỚC 3: CÀI ĐẶT VÀ CẤU HÌNH ANDROID STUDIO

### 3.1. Cài đặt Android Studio
1. Tải bộ cài đặt Android Studio chính thức tại [developer.android.com/studio](https://developer.android.com/studio).
2. Mở file cài đặt, chạy trình hướng dẫn **Setup Wizard**:
   * Chọn kiểu cài đặt **Standard**.
   * Đồng ý với các điều khoản cấp phép và chờ chương trình tải về **Android SDK**, **Platform-Tools**, và **Build-Tools**.

### 3.2. Cài Plugin Flutter & Dart trong Android Studio
1. Mở **Android Studio**.
2. Nhấp vào mục **Plugins** ở menu bên trái.
3. Tại tab **Marketplace**, tìm kiếm `Flutter` -> Nhấn **Install** (Plugin `Dart` sẽ tự động cài đặt kèm theo).
4. Khởi động lại Android Studio để áp dụng plugin.

### 3.3. Cài đặt Android SDK Command-line Tools
1. Tại màn hình chào mừng Android Studio, chọn **More Actions** (hoặc vào **Settings/Preferences**).
2. Chọn **SDK Manager** -> Chuyển sang tab **SDK Tools**.
3. Tích chọn **Android SDK Command-line Tools (latest)**.
4. Nhấn **Apply** -> **OK** để hoàn tất cài đặt.

---

## KIỂM TRA MÔI TRƯỜNG BẰNG FLUTTER DOCTOR

Mở cửa sổ Terminal/CMD mới (đã tắt mở lại sau khi sửa PATH) và chạy lệnh:

```bash
flutter doctor
```

### Xử lý yêu cầu chấp nhận bản quyền (Android Licenses) nếu có:
Nếu `flutter doctor` báo thiếu Android License, hãy chạy lệnh sau và nhập `y` cho tất cả câu hỏi:
```bash
flutter doctor --android-licenses
```

---
*Tài liệu thuộc chuỗi hướng dẫn phát triển dự án **Agribank Alert**.*