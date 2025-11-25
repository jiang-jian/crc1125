import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_theme.dart';
import '../../../data/services/keyboard_service.dart';
import '../../../data/models/keyboard_device_model.dart';

/// 外置键盘配置页面
/// 布局：左侧设备信息 | 右侧配置区域（待实现）
class KeyboardConfigView extends StatefulWidget {
  const KeyboardConfigView({super.key});

  @override
  State<KeyboardConfigView> createState() => _KeyboardConfigViewState();
}

class _KeyboardConfigViewState extends State<KeyboardConfigView> {
  // 获取键盘服务
  late final KeyboardService _keyboardService;

  // FocusNode用于捕获键盘输入
  final FocusNode _keyboardFocusNode = FocusNode();

  // 测试功能状态
  final RxString _inputBuffer = ''.obs; // 输入缓冲区
  final RxString _outputText = ''.obs; // 输出显示文本
  final RxBool _showSuccessAnimation = false.obs; // 成功动画标志

  @override
  void initState() {
    super.initState();
    // 获取全局键盘服务实例
    _keyboardService = Get.find<KeyboardService>();

    // 监听键盘输入事件
    ever(_keyboardService.lastKeyData, _handleKeyInput);

    // 自动扫描设备
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardService.scanUsbKeyboards();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  /// 处理RawKeyEvent（直接捕获物理键盘输入）
  void _handleRawKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final logicalKey = event.logicalKey;
    final keyLabel = event.character;

    // 处理删除键
    if (logicalKey == LogicalKeyboardKey.backspace) {
      if (_inputBuffer.value.isNotEmpty) {
        _inputBuffer.value = _inputBuffer.value.substring(0, _inputBuffer.value.length - 1);
      }
      return;
    }

    // 处理回车键
    if (logicalKey == LogicalKeyboardKey.enter || logicalKey == LogicalKeyboardKey.numpadEnter) {
      _inputBuffer.value += '\n';
      return;
    }

    // 处理可打印字符（包括数字、字母、符号）
    if (keyLabel != null && keyLabel.isNotEmpty) {
      _inputBuffer.value += keyLabel;
    }
  }

  /// 处理键盘输入（数字键盘优先支持）- 保留用于Native层事件
  void _handleKeyInput(Map<String, dynamic> keyData) {
    if (keyData.isEmpty) return;

    final keyCode = keyData['keyCode'] as int?;
    final keyChar = keyData['keyChar'] as String?;

    if (keyCode == null) return;

    // 数字键盘KeyCode映射 (优先处理)
    String? char = _mapNumericKeypadKeyCode(keyCode);

    // 如果不是数字键盘按键，使用keyChar
    if (char == null && keyChar != null && keyChar.isNotEmpty) {
      char = keyChar;
    }

    // 添加到输入缓冲区
    if (char != null && char.isNotEmpty) {
      _inputBuffer.value += char;
    }
  }

  /// 映射数字键盘KeyCode到字符
  /// Android KeyEvent常量参考：https://developer.android.com/reference/android/view/KeyEvent
  String? _mapNumericKeypadKeyCode(int keyCode) {
    // 数字键盘数字键 (NUMPAD_0 到 NUMPAD_9)
    if (keyCode >= 144 && keyCode <= 153) {
      // KeyCode 144=NUMPAD_0, 145=NUMPAD_1, ..., 153=NUMPAD_9
      return (keyCode - 144).toString();
    }

    // 数字键盘运算符
    // Android KeyEvent常量: https://developer.android.com/reference/android/view/KeyEvent
    switch (keyCode) {
      case 158: // NUMPAD_DOT (.)
        return '.';
      case 154: // NUMPAD_DIVIDE (/)
        return '/';
      case 155: // NUMPAD_MULTIPLY (*)
        return '*';
      case 156: // NUMPAD_SUBTRACT (-)
        return '-';
      case 157: // NUMPAD_ADD (+)
        return '+';
      case 160: // NUMPAD_ENTER
        return '\n';
      case 66: // ENTER (主键盘)
        return '\n';
      case 67: // DEL/BACKSPACE
        // 删除最后一个字符
        if (_inputBuffer.value.isNotEmpty) {
          _inputBuffer.value = _inputBuffer.value.substring(0, _inputBuffer.value.length - 1);
        }
        return null;
      default:
        return null;
    }
  }

  /// 执行测试输出
  void _performTestOutput() {
    // 立即请求焦点，防止软键盘弹出
    _keyboardFocusNode.requestFocus();
    
    if (_inputBuffer.value.isEmpty) {
      Get.snackbar(
        '提示',
        '请先输入内容',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.warningColor.withValues(alpha: 0.9),
        colorText: Colors.white,
        icon: const Icon(Icons.warning, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // 输出到显示区域
    _outputText.value = _inputBuffer.value;

    // 显示成功动画
    _showSuccessAnimation.value = true;

    // 2秒后隐藏动画
    Future.delayed(const Duration(seconds: 2), () {
      _showSuccessAnimation.value = false;
    });

    // 清空输入缓冲区
    _inputBuffer.value = '';
  }

  /// 清空所有内容
  void _clearAll() {
    // 立即请求焦点，防止软键盘弹出
    _keyboardFocusNode.requestFocus();
    
    _inputBuffer.value = '';
    _outputText.value = '';
    _showSuccessAnimation.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 点击页面任何地方都重新获取焦点，防止软键盘弹出
        _keyboardFocusNode.requestFocus();
      },
      child: RawKeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKey: _handleRawKeyEvent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.white,
          child: Row(
            children: [
          // 左列：设备信息区 (40%)
          Expanded(
            flex: 40,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 40.h),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                border: Border(
                  right: BorderSide(color: AppTheme.borderColor, width: 1.w),
                ),
              ),
              child: _buildDeviceInfoSection(),
            ),
          ),

          // 右列：配置区域 (60%) - 待实现
          Expanded(
            flex: 60,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 40.h),
              color: Colors.white,
              child: _buildConfigSection(),
            ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  /// 构建左列：设备信息区
  Widget _buildDeviceInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题
        Text(
          '键盘设备',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),

        SizedBox(height: 40.h),

        // 扫描设备按钮
        _buildScanDeviceButton(),

        SizedBox(height: 40.h),

        // 设备列表或空状态
        Expanded(
          child: Obx(() {
            if (_keyboardService.isScanning.value) {
              return _buildScanningDevicesState();
            } else if (_keyboardService.detectedKeyboards.isEmpty) {
              return _buildNoDeviceState();
            } else {
              return _buildDevicesList();
            }
          }),
        ),
      ],
    );
  }

  /// 扫描设备按钮
  Widget _buildScanDeviceButton() {
    return Obx(() {
      final isScanning = _keyboardService.isScanning.value;
      return SizedBox(
        height: 56.h,
        child: ElevatedButton.icon(
          onPressed:
              isScanning ? null : () => _keyboardService.scanUsbKeyboards(),
          icon: isScanning
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.refresh, size: 22.sp),
          label: Text(
            isScanning ? '扫描中...' : '扫描USB设备',
            style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
          ),
        ),
      );
    });
  }

  /// 扫描设备中状态
  Widget _buildScanningDevicesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50.w,
            height: 50.h,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5B544)),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            '扫描中...',
            style: TextStyle(fontSize: 16.sp, color: AppTheme.textTertiary),
          ),
        ],
          ),
        ),
      ),
    );
  }

  /// 无设备状态
  Widget _buildNoDeviceState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard_outlined,
            size: 60.sp,
            color: const Color(0xFFBDC3C7),
          ),
          SizedBox(height: 16.h),
          Text(
            '未检测到键盘设备',
            style: TextStyle(fontSize: 16.sp, color: AppTheme.textTertiary),
          ),
          SizedBox(height: 8.h),
          Text(
            '请连接USB键盘设备',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFFBDC3C7)),
          ),
        ],
          ),
        ),
      ),
    );
  }

  /// 设备列表
  Widget _buildDevicesList() {
    return Obx(() {
      final devices = _keyboardService.detectedKeyboards;
      final selectedDevice = _keyboardService.selectedKeyboard.value;

      return ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final device = devices[index];
          final isSelected = selectedDevice?.deviceId == device.deviceId;
          final isConnected = device.isConnected;

          return _buildDeviceCard(
            device: device,
            isSelected: isSelected,
            isConnected: isConnected,
            onTap: () => _handleDeviceTap(device, isConnected),
          );
        },
      );
    });
  }

  /// 处理设备点击
  Future<void> _handleDeviceTap(
      KeyboardDevice device, bool isConnected) async {
    // 立即请求焦点，防止软键盘弹出
    _keyboardFocusNode.requestFocus();
    
    if (!isConnected) {
      // 请求权限
      final granted = await _keyboardService.requestPermission(device.deviceId);
      if (granted) {
        // 等待权限授予后重新扫描
        await Future.delayed(const Duration(milliseconds: 500));
        await _keyboardService.scanUsbKeyboards();

        // 查找更新后的设备
        final updatedDevice = _keyboardService.detectedKeyboards
            .firstWhereOrNull((d) =>
                d.vendorId == device.vendorId &&
                d.productId == device.productId &&
                (device.serialNumber == null ||
                    d.serialNumber == device.serialNumber));

        if (updatedDevice != null && updatedDevice.isConnected) {
          _keyboardService.selectedKeyboard.value = updatedDevice;
          await _keyboardService.startListening();

          Get.snackbar(
            '授权成功',
            '键盘设备 "${updatedDevice.deviceName}" 已连接',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppTheme.successColor.withValues(alpha: 0.9),
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        Get.snackbar(
          '等待授权',
          '请在系统弹窗中允许访问USB设备',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.info, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } else {
      // 选择设备并开始监听
      _keyboardService.selectedKeyboard.value = device;
      await _keyboardService.startListening();
    }
  }

  /// 设备卡片
  Widget _buildDeviceCard({
    required KeyboardDevice device,
    required bool isSelected,
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnected ? onTap : null,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRound),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
                width: isSelected ? 2.w : 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 设备标题行
                Row(
                  children: [
                    // 键盘图标
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : AppTheme.textTertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _getKeyboardIcon(device.keyboardType),
                        size: 24.sp,
                        color: isConnected
                            ? AppTheme.primaryColor
                            : AppTheme.textTertiary,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // 设备名称
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.deviceName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _getKeyboardTypeLabel(device.keyboardType),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 连接状态标签
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isConnected
                            ? AppTheme.successColor.withValues(alpha: 0.1)
                            : AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Text(
                        isConnected ? '已连接' : '未连接',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isConnected
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // 设备详情
                _buildDeviceInfoRow(
                  icon: Icons.tag,
                  label: '设备ID',
                  value: device.deviceId,
                ),

                if (device.manufacturer != null) ...[
                  SizedBox(height: 8.h),
                  _buildDeviceInfoRow(
                    icon: Icons.business,
                    label: '制造商',
                    value: device.manufacturer!,
                  ),
                ],

                if (device.vendorId > 0) ...[
                  SizedBox(height: 8.h),
                  _buildDeviceInfoRow(
                    icon: Icons.numbers,
                    label: 'VID/PID',
                    value:
                        '0x${device.vendorId.toRadixString(16).toUpperCase()} / 0x${device.productId.toRadixString(16).toUpperCase()}',
                  ),
                ],

                // 授权按钮（仅在未连接时显示）
                if (!isConnected) ...[
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 40.h,
                    child: ElevatedButton.icon(
                      onPressed: onTap,
                      icon: Icon(Icons.vpn_key, size: 18.sp),
                      label: Text(
                        '授权连接',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.sp,
                          color: AppTheme.warningColor,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '点击「授权连接」按钮以使用设备',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppTheme.warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 设备信息行
  Widget _buildDeviceInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: AppTheme.textTertiary,
        ),
        SizedBox(width: 8.w),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13.sp,
            color: AppTheme.textTertiary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.textSecondary,
              fontFamily: 'monospace',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 构建右列：键盘测试区域
  Widget _buildConfigSection() {
    return Obx(() {
      final hasSelectedDevice = _keyboardService.selectedKeyboard.value != null;

      // 只要选择了设备就显示测试UI，不强制要求监听状态
      if (!hasSelectedDevice) {
        return _buildNoDeviceSelectedState();
      }

      return _buildKeyboardTestUI();
    });
  }

  /// 未选择设备状态
  Widget _buildNoDeviceSelectedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard_alt_outlined,
            size: 80.sp,
            color: const Color(0xFFBDC3C7),
          ),
          SizedBox(height: 24.h),
          Text(
            '请先选择并连接键盘设备',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '在左侧设备列表中选择键盘设备后，即可开始测试',
            style: TextStyle(
              fontSize: 15.sp,
              color: AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
          ),
        ),
      ),
    );
  }

  /// 键盘测试UI
  Widget _buildKeyboardTestUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Row(
          children: [
            Icon(
              Icons.keyboard_alt,
              size: 28.sp,
              color: AppTheme.primaryColor,
            ),
            SizedBox(width: 12.w),
            Text(
              '键盘输入测试',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            // 清空按钮
            TextButton.icon(
              onPressed: _clearAll,
              icon: Icon(Icons.clear_all, size: 18.sp),
              label: Text(
                '清空',
                style: TextStyle(fontSize: 15.sp),
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        // 提示信息
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18.sp,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  '使用外置键盘输入字符和数字，内容会实时显示在下方输入框中',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.primaryColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32.h),

        // 文本输入显示区域
        _buildInputDisplayArea(),

        SizedBox(height: 24.h),

        // 测试输出按钮
        _buildTestOutputButton(),

        SizedBox(height: 32.h),

        // 输出内容显示区域
        _buildOutputDisplayArea(),
      ],
    );
  }

  /// 文本输入显示区域
  Widget _buildInputDisplayArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '键盘输入内容',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Obx(() {
          return Container(
            width: double.infinity,
            height: 120.h,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _inputBuffer.value.isNotEmpty
                    ? AppTheme.primaryColor
                    : AppTheme.borderColor,
                width: _inputBuffer.value.isNotEmpty ? 2.w : 1.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Text(
                _inputBuffer.value.isEmpty
                    ? '请使用外置键盘输入...'
                    : _inputBuffer.value,
                style: TextStyle(
                  fontSize: 18.sp,
                  color: _inputBuffer.value.isEmpty
                      ? AppTheme.textTertiary
                      : AppTheme.textPrimary,
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 测试输出按钮
  Widget _buildTestOutputButton() {
    return Obx(() {
      final hasInput = _inputBuffer.value.isNotEmpty;
      return SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton.icon(
          onPressed: hasInput ? _performTestOutput : null,
          icon: Icon(Icons.send, size: 20.sp),
          label: Text(
            '测试输出',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppTheme.borderColor,
            disabledForegroundColor: AppTheme.textTertiary,
            elevation: hasInput ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      );
    });
  }

  /// 输出内容显示区域
  Widget _buildOutputDisplayArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '输出内容',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        Obx(() {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 180.h,
              maxHeight: 300.h,
            ),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: _outputText.value.isNotEmpty
                  ? AppTheme.successColor.withValues(alpha: 0.05)
                  : AppTheme.backgroundGrey,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _outputText.value.isNotEmpty
                    ? AppTheme.successColor.withValues(alpha: 0.3)
                    : AppTheme.borderColor,
                width: 1.w,
              ),
              boxShadow: _outputText.value.isNotEmpty
                  ? [
                      BoxShadow(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                // 输出文本
                SingleChildScrollView(
                  child: Text(
                    _outputText.value.isEmpty
                        ? '点击「测试输出」按钮后，输入内容将显示在这里'
                        : _outputText.value,
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: _outputText.value.isEmpty
                          ? AppTheme.textTertiary
                          : AppTheme.textPrimary,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),

                // 成功动画
                if (_showSuccessAnimation.value)
                  Positioned.fill(
                    child: _buildSuccessAnimation(),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// 成功动画
  Widget _buildSuccessAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 64.sp,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '测试成功！',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '键盘输入功能正常',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ========== 辅助方法 ==========

  /// 获取键盘类型图标
  IconData _getKeyboardIcon(String keyboardType) {
    switch (keyboardType) {
      case 'numeric':
        return Icons.dialpad;
      case 'full':
        return Icons.keyboard;
      default:
        return Icons.keyboard_outlined;
    }
  }

  /// 获取键盘类型标签
  String _getKeyboardTypeLabel(String keyboardType) {
    switch (keyboardType) {
      case 'numeric':
        return '数字键盘';
      case 'full':
        return '全键盘';
      default:
        return '标准键盘';
    }
  }
}
