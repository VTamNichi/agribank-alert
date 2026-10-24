const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

/**
 * Tạo mã ghép nối tạm thời (hết hạn sau 10 phút)
 */
exports.generatePairCode = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { deviceId, deviceName } = req.body;
  if (!deviceId) {
    return res.status(400).json({ error: 'Thiếu deviceId' });
  }

  try {
    const randomNum = Math.floor(1000 + Math.random() * 9000);
    const pairCode = `AG-${randomNum}`;
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 phút

    await db.collection('pair_codes').doc(pairCode).set({
      pairCode,
      creatorDeviceId: deviceId,
      creatorDeviceName: deviceName || 'Thiết bị Agribank',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
      status: 'active',
    });

    return res.status(200).json({
      success: true,
      pairCode,
      expiresAt: expiresAt.toISOString(),
    });
  } catch (error) {
    console.error('Lỗi tạo mã ghép nối:', error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * Ghép cặp 2 thiết bị thông qua Mã Ghép Nối
 */
exports.pairDevice = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { pairCode, deviceId, deviceName } = req.body;
  if (!pairCode || !deviceId) {
    return res.status(400).json({ error: 'Thiếu pairCode hoặc deviceId' });
  }

  try {
    const codeDoc = await db.collection('pair_codes').doc(pairCode.trim()).get();
    if (!codeDoc.exists) {
      return res.status(404).json({ error: 'Mã ghép nối không tồn tại' });
    }

    const codeData = codeDoc.data();
    const now = Date.now();
    const expiresAtMs = codeData.expiresAt.toMillis();

    if (now > expiresAtMs || codeData.status !== 'active') {
      return res.status(400).json({ error: 'Mã ghép nối đã hết hạn hoặc đã được sử dụng' });
    }

    const hostDeviceId = codeData.creatorDeviceId;
    const hostDeviceName = codeData.creatorDeviceName;

    // Lưu liên kết ghép cặp 2 chiều
    const batch = db.batch();
    const pairRefA = db.collection('paired_devices').doc(hostDeviceId);
    const pairRefB = db.collection('paired_devices').doc(deviceId);

    batch.set(pairRefA, {
      pairedWithDeviceId: deviceId,
      pairedWithDeviceName: deviceName || 'Thiết bị đối tác',
      pairedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    batch.set(pairRefB, {
      pairedWithDeviceId: hostDeviceId,
      pairedWithDeviceName: hostDeviceName,
      pairedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Đánh dấu mã đã sử dụng
    batch.update(codeDoc.ref, { status: 'used' });
    await batch.commit();

    return res.status(200).json({
      success: true,
      message: 'Ghép cặp thành công',
      pairedDeviceId: hostDeviceId,
      pairedDeviceName: hostDeviceName,
    });
  } catch (error) {
    console.error('Lỗi khi ghép cặp:', error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * Đăng ký hoặc cập nhật FCM Token của thiết bị
 */
exports.registerFcmToken = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { deviceId, fcmToken, deviceName } = req.body;
  if (!deviceId || !fcmToken) {
    return res.status(400).json({ error: 'Thiếu deviceId hoặc fcmToken' });
  }

  try {
    await db.collection('devices').doc(deviceId).set({
      deviceId,
      fcmToken,
      deviceName: deviceName || 'Thiết bị Agribank',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return res.status(200).json({ success: true });
  } catch (error) {
    console.error('Lỗi đăng ký FCM token:', error);
    return res.status(500).json({ error: error.message });
  }
});

/**
 * Chuyển tiếp sự kiện giao dịch nhận tiền từ Điện thoại A sang Điện thoại B
 */
exports.forwardAlert = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const { alert, senderDeviceId, targetDeviceId } = req.body;
  if (!alert || !alert.eventId || !alert.amount) {
    return res.status(400).json({ error: 'Dữ liệu giao dịch không hợp lệ' });
  }

  try {
    const eventId = alert.eventId;

    // 1. Chống trùng lặp trên Backend: kiểm tra xem eventId đã từng được xử lý chưa
    const processedDoc = await db.collection('processed_events').doc(eventId).get();
    if (processedDoc.exists) {
      return res.status(200).json({
        success: false,
        duplicate: true,
        message: 'Giao dịch này đã được chuyển tiếp trước đó (Event ID trùng lặp)',
      });
    }

    // 2. Ghi nhận sự kiện đã xử lý
    await db.collection('processed_events').doc(eventId).set({
      eventId,
      senderDeviceId: senderDeviceId || 'unknown',
      amount: alert.amount,
      occurredAt: alert.occurredAt || new Date().toISOString(),
      processedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 3. Lưu lịch sử giao dịch
    await db.collection('transactions').doc(eventId).set({
      ...alert,
      senderDeviceId: senderDeviceId || 'unknown',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // 4. Nếu có targetDeviceId, tìm FCM Token và đẩy thông báo FCM
    let fcmSent = false;
    if (targetDeviceId) {
      const targetDoc = await db.collection('devices').doc(targetDeviceId).get();
      if (targetDoc.exists && targetDoc.data().fcmToken) {
        const fcmToken = targetDoc.data().fcmToken;

        const message = {
          token: fcmToken,
          data: {
            eventId: String(alert.eventId),
            amount: String(alert.amount),
            currency: alert.currency || 'VND',
            direction: alert.direction || 'credit',
            occurredAt: String(alert.occurredAt || ''),
            accountNumber: String(alert.accountNumber || ''),
            senderName: String(alert.senderName || ''),
            referenceCode: String(alert.referenceCode || ''),
            rawTitle: String(alert.rawTitle || ''),
            rawContent: String(alert.rawContent || ''),
          },
          android: {
            priority: 'high',
          },
        };

        await admin.messaging().send(message);
        fcmSent = true;
      }
    }

    return res.status(200).json({
      success: true,
      message: fcmSent
        ? 'Đã chuyển tiếp thông báo đến thiết bị B qua FCM thành công'
        : 'Đã lưu giao dịch vào cơ sở dữ liệu chuyển tiếp',
      eventId,
    });
  } catch (error) {
    console.error('Lỗi chuyển tiếp giao dịch:', error);
    return res.status(500).json({ error: error.message });
  }
});
