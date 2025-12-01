import 'package:get/get.dart';
import '../models/scanner_box_model.dart';

/// 扫码盒子服务（暂时使用模拟数据，后续对接底层）
class ScannerBoxService extends GetxService {
  // ==================== 响应式状态 ====================

  /// 当前连接的设备
  final Rx<ScannerBoxDevice?> connectedDevice = Rx<ScannerBoxDevice?>(null);

  /// 设备状态
  final Rx<ScannerBoxStatus> deviceStatus = ScannerBoxStatus.disconnected.obs;

  /// 扫码历史记录
  final RxList<ScanData> scanHistory = <ScanData>[].obs;

  /// 最新扫码数据
  final Rx<ScanData?> latestScan = Rx<ScanData?>(null);

  /// 是否正在扫描
  final RxBool isScanning = false.obs;

  // ==================== 初始化 ====================

  @override
  void onInit() {
    super.onInit();
    print('[ScannerBox] 服务初始化');
    _initMockData();
  }

  /// 初始化模拟数据（测试用）
  void _initMockData() {
    // 模拟一个已连接的设备
    connectedDevice.value = ScannerBoxDevice(
      deviceId: 'mock_scanner_001',
      deviceName: 'USB扫码盒子',
      vendorId: 1234,
      productId: 5678,
      serialNumber: 'SN20250101001',
      manufacturer: '虚拟厂商',
      productName: '高速扫码盒子 Pro',
      isConnected: true,
      isAuthorized: true,
    );
    deviceStatus.value = ScannerBoxStatus.connected;

    // 添加一些模拟扫码记录
    scanHistory.addAll([
      ScanData(
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        content: 'https://example.com/product/12345',
        type: 'QR',
      ),
      ScanData(
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        content: '9787115123456',
        type: 'Barcode',
      ),
    ]);

    print('[ScannerBox] 模拟数据加载完成');
  }

  // ==================== 设备管理 ====================

  /// 扫描USB设备
  Future<List<ScannerBoxDevice>> scanDevices() async {
    print('[ScannerBox] 开始扫描设备...');
    await Future.delayed(const Duration(seconds: 1));

    // 模拟扫描结果
    final mockDevices = [
      ScannerBoxDevice(
        deviceId: 'mock_scanner_001',
        deviceName: 'USB扫码盒子',
        vendorId: 1234,
        productId: 5678,
        serialNumber: 'SN20250101001',
        manufacturer: '虚拟厂商',
        productName: '高速扫码盒子 Pro',
        isConnected: false,
        isAuthorized: false,
      ),
    ];

    print('[ScannerBox] 扫描完成，发现 ${mockDevices.length} 个设备');
    return mockDevices;
  }

  /// 请求设备授权
  Future<bool> requestAuthorization(ScannerBoxDevice device) async {
    print('[ScannerBox] 请求授权设备: ${device.displayName}');
    await Future.delayed(const Duration(seconds: 1));

    // 模拟授权成功
    connectedDevice.value = device.copyWith(
      isConnected: true,
      isAuthorized: true,
    );
    deviceStatus.value = ScannerBoxStatus.connected;

    print('[ScannerBox] 授权成功');
    return true;
  }

  /// 断开设备连接
  Future<void> disconnect() async {
    print('[ScannerBox] 断开设备连接');
    await Future.delayed(const Duration(milliseconds: 500));

    connectedDevice.value = null;
    deviceStatus.value = ScannerBoxStatus.disconnected;
    isScanning.value = false;

    print('[ScannerBox] 已断开连接');
  }

  // ==================== 扫码功能 ====================

  /// 开始监听扫码数据
  Future<void> startScanning() async {
    if (connectedDevice.value == null) {
      print('[ScannerBox] 错误：未连接设备');
      return;
    }

    if (isScanning.value) {
      print('[ScannerBox] 已经在扫描中');
      return;
    }

    print('[ScannerBox] 开始监听扫码数据');
    isScanning.value = true;
    deviceStatus.value = ScannerBoxStatus.scanning;

    // TODO: 后续对接底层SDK，监听扫码事件
    // 这里暂时使用模拟数据
    _startMockScanning();
  }

  /// 停止监听扫码数据
  Future<void> stopScanning() async {
    print('[ScannerBox] 停止监听扫码数据');
    isScanning.value = false;
    deviceStatus.value = ScannerBoxStatus.connected;
  }

  /// 模拟扫码（测试用）
  void _startMockScanning() {
    // 每10秒模拟一次扫码
    Future.delayed(const Duration(seconds: 10), () {
      if (isScanning.value) {
        _addMockScan();
        _startMockScanning(); // 继续监听
      }
    });
  }

  /// 添加模拟扫码数据
  void _addMockScan() {
    final mockData = ScanData(
      timestamp: DateTime.now(),
      content: 'MOCK_${DateTime.now().millisecondsSinceEpoch}',
      type: 'QR',
    );

    addScanData(mockData);
  }

  /// 添加扫码数据（供底层调用）
  void addScanData(ScanData data) {
    print('[ScannerBox] 收到扫码数据: ${data.content}');

    latestScan.value = data;
    scanHistory.insert(0, data); // 最新的在前面

    // 限制历史记录数量（最多保留100条）
    if (scanHistory.length > 100) {
      scanHistory.removeRange(100, scanHistory.length);
    }
  }

  /// 清空扫码历史
  void clearHistory() {
    print('[ScannerBox] 清空扫码历史');
    scanHistory.clear();
    latestScan.value = null;
  }

  // ==================== 工具方法 ====================

  /// 获取设备状态文本
  String getStatusText() {
    switch (deviceStatus.value) {
      case ScannerBoxStatus.disconnected:
        return '未连接';
      case ScannerBoxStatus.connected:
        return '已连接';
      case ScannerBoxStatus.scanning:
        return '扫描中';
      case ScannerBoxStatus.error:
        return '错误';
    }
  }

  @override
  void onClose() {
    print('[ScannerBox] 服务销毁');
    disconnect();
    super.onClose();
  }
}
