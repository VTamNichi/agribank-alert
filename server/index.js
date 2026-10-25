const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// ============================
// Bộ nhớ trong RAM (In-Memory)
// ============================
const pairCodes = new Map();       // pairCode -> { creatorDeviceId, creatorDeviceName, createdAt }
const pairedDevices = new Map();   // deviceId -> { pairedWithDeviceId, pairedWithDeviceName }
const deviceSockets = new Map();   // deviceId -> WebSocket connection
const processedEvents = new Set(); // eventId set (chống trùng lặp)

// Tự xóa pairCode hết hạn sau 10 phút
setInterval(() => {
  const now = Date.now();
  for (const [code, data] of pairCodes.entries()) {
    if (now - data.createdAt > 10 * 60 * 1000) {
      pairCodes.delete(code);
    }
  }
  // Giữ processedEvents không quá 5000 entry
  if (processedEvents.size > 5000) {
    const arr = Array.from(processedEvents);
    for (let i = 0; i < arr.length - 2000; i++) {
      processedEvents.delete(arr[i]);
    }
  }
}, 60 * 1000);

// ============================
// REST API Endpoints
// ============================

// Kiểm tra server còn sống
app.get('/', (req, res) => {
  res.json({
    status: 'ok',
    name: 'Agribank Alert Relay Server',
    version: '1.0.0',
    connectedDevices: deviceSockets.size,
    activePairCodes: pairCodes.size,
    pairedDevices: pairedDevices.size,
  });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Tạo mã ghép nối
app.post('/generatePairCode', (req, res) => {
  const { deviceId, deviceName } = req.body;
  if (!deviceId) return res.status(400).json({ error: 'Thiếu deviceId' });

  const randomNum = Math.floor(1000 + Math.random() * 9000);
  const pairCode = `AG-${randomNum}`;

  pairCodes.set(pairCode, {
    creatorDeviceId: deviceId,
    creatorDeviceName: deviceName || 'Thiết bị Agribank',
    createdAt: Date.now(),
  });

  console.log(`[PairCode] Tạo mã ${pairCode} cho thiết bị ${deviceId}`);
  res.json({ success: true, pairCode });
});

// Đăng ký mã ghép nối từ máy điện thoại lên server
app.post('/registerPairCode', (req, res) => {
  const { pairCode, deviceId, deviceName } = req.body;
  if (!pairCode || !deviceId) {
    return res.status(400).json({ error: 'Thiếu pairCode hoặc deviceId' });
  }

  const cleanCode = pairCode.trim().toUpperCase();
  pairCodes.set(cleanCode, {
    creatorDeviceId: deviceId,
    creatorDeviceName: deviceName || 'Thiết bị Agribank',
    createdAt: Date.now(),
  });

  console.log(`[PairCode] Đăng ký mã ${cleanCode} cho thiết bị ${deviceId}`);
  res.json({ success: true, pairCode: cleanCode });
});

// Ghép cặp 2 thiết bị
app.post('/pairDevice', (req, res) => {
  const { pairCode, deviceId, deviceName } = req.body;
  if (!pairCode || !deviceId) {
    return res.status(400).json({ error: 'Thiếu pairCode hoặc deviceId' });
  }

  const cleanCode = pairCode.trim().toUpperCase();
  let hostDeviceId = null;
  let hostDeviceName = 'Thiết bị đối tác';

  // 1. Kiểm tra trong danh sách mã đã đăng ký
  if (pairCodes.has(cleanCode)) {
    const codeData = pairCodes.get(cleanCode);
    hostDeviceId = codeData.creatorDeviceId;
    hostDeviceName = codeData.creatorDeviceName;
  }
  // 2. Hoặc người dùng nhập thẳng Device ID
  else if (deviceSockets.has(cleanCode)) {
    hostDeviceId = cleanCode;
  }
  // 3. Nếu server có thiết bị khác đang online qua WebSocket, tự động ghép
  else {
    for (const [sId, ws] of deviceSockets.entries()) {
      if (sId !== deviceId) {
        hostDeviceId = sId;
        break;
      }
    }
  }

  if (!hostDeviceId) {
    return res.status(404).json({
      error: 'Mã ghép nối không tồn tại hoặc Máy B chưa kết nối. Hãy đảm bảo cả 2 máy đều đã nhập đúng link server và Máy B đang mở app.',
    });
  }

  // Lưu liên kết ghép cặp 2 chiều
  pairedDevices.set(hostDeviceId, {
    pairedWithDeviceId: deviceId,
    pairedWithDeviceName: deviceName || 'Thiết bị đối tác',
  });
  pairedDevices.set(deviceId, {
    pairedWithDeviceId: hostDeviceId,
    pairedWithDeviceName: hostDeviceName,
  });

  console.log(`[Pair] Ghép cặp thành công: ${hostDeviceId} <-> ${deviceId}`);

  // Thông báo cho cả 2 thiết bị nếu đang online qua WebSocket
  const hostSocket = deviceSockets.get(hostDeviceId);
  if (hostSocket && hostSocket.readyState === WebSocket.OPEN) {
    hostSocket.send(JSON.stringify({
      type: 'paired',
      pairedDeviceId: deviceId,
      pairedDeviceName: deviceName || 'Thiết bị đối tác',
    }));
  }

  res.json({
    success: true,
    message: 'Ghép cặp thành công',
    pairedDeviceId: hostDeviceId,
    pairedDeviceName: hostDeviceName,
  });
});

// Tự động ghép cặp với thiết bị còn lại trên server
app.post('/autoPair', (req, res) => {
  const { deviceId, deviceName } = req.body;
  if (!deviceId) return res.status(400).json({ error: 'Thiếu deviceId' });

  let targetId = null;
  let targetName = 'Thiết bị đối tác';

  // 1. Tìm trong thiết bị online qua WebSocket
  for (const [sId, ws] of deviceSockets.entries()) {
    if (sId !== deviceId) {
      targetId = sId;
      break;
    }
  }

  // 2. Tìm trong danh sách mã đã đăng ký
  if (!targetId) {
    for (const [code, data] of pairCodes.entries()) {
      if (data.creatorDeviceId !== deviceId) {
        targetId = data.creatorDeviceId;
        targetName = data.creatorDeviceName;
        break;
      }
    }
  }

  // 3. Tìm trong danh sách thiết bị đã từng kết nối
  if (!targetId) {
    for (const [dId, data] of pairedDevices.entries()) {
      if (dId !== deviceId) {
        targetId = dId;
        break;
      }
    }
  }

  if (!targetId) {
    return res.status(404).json({
      error: 'Chưa tìm thấy thiết bị thứ hai trên server. Hãy đảm bảo cả 2 máy đều đã nhập đúng link server và đang mở ứng dụng.',
    });
  }

  pairedDevices.set(deviceId, { pairedWithDeviceId: targetId, pairedWithDeviceName: targetName });
  pairedDevices.set(targetId, { pairedWithDeviceId: deviceId, pairedWithDeviceName: deviceName || 'Thiết bị đối tác' });

  console.log(`[AutoPair] Đã tự động ghép cặp: ${deviceId} <-> ${targetId}`);

  // Báo cho thiết bị đối tác qua WebSocket
  const targetSocket = deviceSockets.get(targetId);
  if (targetSocket && targetSocket.readyState === WebSocket.OPEN) {
    targetSocket.send(JSON.stringify({
      type: 'paired',
      pairedDeviceId: deviceId,
      pairedDeviceName: deviceName || 'Thiết bị đối tác',
    }));
  }

  res.json({
    success: true,
    message: 'Ghép cặp tự động thành công!',
    pairedDeviceId: targetId,
    pairedDeviceName: targetName,
  });
});

// Chuyển tiếp thông báo giao dịch từ A sang B
app.post('/forwardAlert', (req, res) => {
  const { alert, senderDeviceId, targetDeviceId } = req.body;

  if (!alert || !alert.eventId || alert.amount == null) {
    return res.status(400).json({ error: 'Dữ liệu giao dịch không hợp lệ' });
  }

  const eventId = alert.eventId;

  // Chống trùng lặp trên server
  if (processedEvents.has(eventId)) {
    return res.json({
      success: false,
      duplicate: true,
      message: 'Giao dịch này đã được chuyển tiếp trước đó',
    });
  }
  processedEvents.add(eventId);

  // Tìm thiết bị đích
  let actualTargetId = targetDeviceId;
  if (!actualTargetId && senderDeviceId) {
    const pair = pairedDevices.get(senderDeviceId);
    if (pair) {
      actualTargetId = pair.pairedWithDeviceId;
    }
  }
  // Fallback: Nếu chưa xác định được targetId, tự động chuyển cho thiết bị đang online còn lại
  if (!actualTargetId) {
    for (const [sId, ws] of deviceSockets.entries()) {
      if (sId !== senderDeviceId && ws.readyState === WebSocket.OPEN) {
        actualTargetId = sId;
        break;
      }
    }
  }

  console.log(`[Forward] Chuyển tiếp +${alert.amount} VND từ ${senderDeviceId} -> ${actualTargetId}`);

  // Gửi qua WebSocket đến thiết bị B
  let delivered = false;
  if (actualTargetId) {
    const targetSocket = deviceSockets.get(actualTargetId);
    if (targetSocket && targetSocket.readyState === WebSocket.OPEN) {
      targetSocket.send(JSON.stringify({
        type: 'transaction_alert',
        alert: alert,
        senderDeviceId: senderDeviceId,
        deliveredAt: new Date().toISOString(),
      }));
      delivered = true;
      console.log(`[Forward] ✅ Đã gửi thành công đến ${actualTargetId} qua WebSocket`);
    } else {
      console.log(`[Forward] ⚠️ Thiết bị ${actualTargetId} không online. Lưu vào hàng đợi.`);
      // Lưu vào hàng đợi offline
      if (!global.pendingAlerts) global.pendingAlerts = new Map();
      if (!global.pendingAlerts.has(actualTargetId)) {
        global.pendingAlerts.set(actualTargetId, []);
      }
      const queue = global.pendingAlerts.get(actualTargetId);
      queue.push({ alert, senderDeviceId, savedAt: Date.now() });
      // Giữ tối đa 50 tin nhắn trong hàng đợi
      if (queue.length > 50) queue.shift();
    }
  }

  res.json({
    success: true,
    delivered,
    message: delivered
      ? 'Đã chuyển tiếp thông báo đến thiết bị B thành công (WebSocket)'
      : 'Đã lưu giao dịch. Thiết bị B sẽ nhận khi online.',
    eventId,
  });
});

// Hủy ghép cặp
app.post('/unpair', (req, res) => {
  const { deviceId } = req.body;
  if (!deviceId) return res.status(400).json({ error: 'Thiếu deviceId' });

  const pair = pairedDevices.get(deviceId);
  if (pair) {
    pairedDevices.delete(pair.pairedWithDeviceId);
  }
  pairedDevices.delete(deviceId);

  console.log(`[Unpair] Thiết bị ${deviceId} đã hủy ghép cặp`);
  res.json({ success: true, message: 'Đã hủy ghép cặp' });
});

// ============================
// WebSocket (Kênh thời gian thực cho Điện thoại B)
// ============================
wss.on('connection', (ws, req) => {
  let deviceId = null;

  ws.on('message', (raw) => {
    try {
      const msg = JSON.parse(raw.toString());

      // Đăng ký thiết bị
      if (msg.type === 'register') {
        deviceId = msg.deviceId;
        deviceSockets.set(deviceId, ws);
        console.log(`[WS] Thiết bị ${deviceId} (${msg.deviceName || ''}) đã kết nối WebSocket`);

        ws.send(JSON.stringify({ type: 'registered', deviceId, serverTime: new Date().toISOString() }));

        // Gửi các thông báo đang chờ trong hàng đợi offline
        if (global.pendingAlerts && global.pendingAlerts.has(deviceId)) {
          const pending = global.pendingAlerts.get(deviceId);
          console.log(`[WS] Gửi ${pending.length} thông báo chờ cho ${deviceId}`);
          for (const item of pending) {
            ws.send(JSON.stringify({
              type: 'transaction_alert',
              alert: item.alert,
              senderDeviceId: item.senderDeviceId,
              deliveredAt: new Date().toISOString(),
            }));
          }
          global.pendingAlerts.delete(deviceId);
        }
      }

      // Ping/Pong giữ kết nối
      if (msg.type === 'ping') {
        ws.send(JSON.stringify({ type: 'pong', serverTime: new Date().toISOString() }));
      }
    } catch (e) {
      console.error('[WS] Lỗi parse message:', e.message);
    }
  });

  ws.on('close', () => {
    if (deviceId) {
      deviceSockets.delete(deviceId);
      console.log(`[WS] Thiết bị ${deviceId} đã ngắt kết nối`);
    }
  });

  ws.on('error', (err) => {
    console.error(`[WS] Lỗi kết nối:`, err.message);
  });
});

// Ping tất cả client mỗi 30 giây để giữ kết nối sống
setInterval(() => {
  wss.clients.forEach((ws) => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.ping();
    }
  });
}, 30 * 1000);

// ============================
// Khởi động Server
// ============================
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log('');
  console.log('==========================================');
  console.log('   AGRIBANK ALERT RELAY SERVER v1.0.0');
  console.log('==========================================');
  console.log(`   HTTP  : http://localhost:${PORT}`);
  console.log(`   WS    : ws://localhost:${PORT}`);
  console.log('   Status: ✅ Đang chạy và sẵn sàng');
  console.log('==========================================');
  console.log('');
});
