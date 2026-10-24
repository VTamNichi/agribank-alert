enum DeviceRole {
  sender,    // Điện thoại A: Giám sát thông báo Agribank & Chuyển tiếp
  receiver,  // Điện thoại B: Nhận thông báo & Đọc số tiền bằng giọng nói
  standalone // Chế độ kiểm thử độc lập 2-trong-1
}

extension DeviceRoleExtension on DeviceRole {
  String get displayName {
    switch (this) {
      case DeviceRole.sender:
        return 'Điện thoại A (Máy gửi)';
      case DeviceRole.receiver:
        return 'Điện thoại B (Máy nhận & Loa)';
      case DeviceRole.standalone:
        return 'Chế độ Thử nghiệm (2-trong-1)';
    }
  }

  String get description {
    switch (this) {
      case DeviceRole.sender:
        return 'Cài trên điện thoại có ứng dụng Agribank để bắt biến động số dư và chuyển đi.';
      case DeviceRole.receiver:
        return 'Nhận thông báo qua Internet và đọc to số tiền nhận được bằng giọng nói tiếng Việt.';
      case DeviceRole.standalone:
        return 'Tự bắt thông báo hoặc giả lập và tự đọc to trên cùng một điện thoại (để test).';
    }
  }
}
