# Agribank Alert - Server Chuyển Tiếp Từ Xa (Relay Server)

> **Giải pháp miễn phí 100%** thay thế Firebase Blaze: Không yêu cầu thẻ tín dụng (Visa/Mastercard), hỗ trợ chuyển tiếp thông báo tức thì giữa Điện thoại A và Điện thoại B qua **WebSocket** và **HTTP REST** ở bất kỳ đâu có Internet (4G / khác Wi-Fi).

---

## 1. Tính năng của Server

* **WebSocket thời gian thực (Real-time)**: Điện thoại B kết nối giữ luồng nhận tin liên tục, độ trễ cực thấp (< 0.2s).
* **Hàng đợi thông báo ngoại tuyến (Offline Queue)**: Nếu máy B tạm mất mạng, server lưu lại và bắn ngay khi máy B có mạng trở lại.
* **Ghép cặp thiết bị bằng mã (Pair Code)**: Sinh mã dạng `AG-XXXX` và quản lý liên kết 2 chiều giữa 2 máy.
* **Chống trùng lặp (Deduplication)**: Ngăn không cho một giao dịch bị đẩy lặp lại nhiều lần.

---

## 2. Cách triển khai lên Render.com (Khuyên dùng - Miễn phí vĩnh viễn)

[Render.com](https://render.com) là dịch vụ đám mây miễn phí chất lượng cao, **không đòi hỏi thẻ tín dụng**.

1. Đăng ký tài khoản miễn phí tại **[render.com](https://render.com)** (bằng tài khoản GitHub hoặc Google).
2. Đẩy thư mục dự án lên tài khoản GitHub của bạn (hoặc tạo một repository riêng chứa thư mục `server/`).
3. Trên Render Dashboard, nhấn **New +** -> chọn **Web Service**.
4. Chọn repository GitHub vừa tạo.
5. Điền các thông số:
   * **Name**: `agribank-alert-server`
   * **Runtime**: `Node`
   * **Build Command**: `cd server && npm install` (hoặc `npm install` nếu repo chỉ chứa thư mục server)
   * **Start Command**: `cd server && node index.js` (hoặc `node index.js`)
   * **Instance Type**: `Free`
6. Nhấn **Create Web Service**.
7. Chờ 1-2 phút, Render sẽ cấp cho bạn một đường dẫn URL công khai (dạng `https://agribank-alert-server.onrender.com`).
8. **Mở Agribank Alert trên cả 2 điện thoại** -> vào tab **Ghép cặp** -> dán URL này vào mục **"Cấu hình máy chủ chuyển tiếp"**.

---

## 3. Cách chạy thử ngay trên máy tính cá nhân (Kèm Ngrok)

Nếu bạn muốn chạy thử nghiệm ngay trên máy tính mà không cần deploy lên mây:

1. Mở Terminal tại thư mục `server`:
   ```powershell
   cd C:\Users\Administrator\Downloads\argibank-alert\server
   npm install
   node index.js
   ```
   Server sẽ chạy tại `http://localhost:3000`.

2. Mở một cửa sổ Terminal khác và dùng **Ngrok** (hoặc Cloudflare Tunnel) để tạo link công khai ra Internet:
   ```powershell
   ngrok http 3000
   ```
   Ngrok sẽ cho bạn một URL công khai (ví dụ: `https://abcd-1234.ngrok-free.app`).

3. Dán URL này vào app Agribank Alert trên cả 2 điện thoại là xong!
