import 'package:flutter/material.dart';
import 'tb_rpc_service.dart';

class LedControlCard extends StatefulWidget {
  final String deviceId;
  final TbRpcService rpcService;

  const LedControlCard({
    super.key,
    required this.deviceId,
    required this.rpcService,
  });

  @override
  State<LedControlCard> createState() => _LedControlCardState();
}

class _LedControlCardState extends State<LedControlCard> {
  bool _isLedOn = false;
  bool _isLoading =
      true; // Thay đổi: Mặc định bằng true để xoay loading lúc mới mở thẻ

  @override
  void initState() {
    super.initState();
    _checkInitialState(); // Gọi hàm kiểm tra trạng thái ngay lập tức
  }

  // Hàm gọi Service để check trạng thái thực tế
  Future<void> _checkInitialState() async {
    bool? currentState = await widget.rpcService.getLatestLedState(
      widget.deviceId,
    );

    // Kiểm tra mounted để tránh lỗi giao diện nếu người dùng đóng BottomSheet quá nhanh
    if (mounted) {
      setState(() {
        _isLedOn = currentState ?? false; // Đồng bộ UI với trạng thái thật
        _isLoading = false; // Tắt vòng xoay loading
      });
    }
  }

  void _handleToggle(bool newValue) async {
    setState(() {
      _isLoading = true;
    });

    // Thực hiện gọi API RPC thông qua Service
    bool isSuccess = await widget.rpcService.sendLedRpcRequest(
      widget.deviceId,
      newValue,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (isSuccess) {
          _isLedOn = newValue; // Cập nhật giao diện nếu thành công
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Không thể kết nối hoặc gửi lệnh tới thiết bị!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  _isLedOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  color: _isLedOn ? Colors.green : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Điều khiển Đèn LED',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isLedOn ? Colors.green[700] : Colors.black87,
                  ),
                ),
              ],
            ),
            _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Switch(
                    value: _isLedOn,
                    onChanged: (bool newValue) {
                      _handleToggle(newValue);
                    },
                    activeThumbColor: Colors.green,
                  ),
          ],
        ),
      ),
    );
  }
}
