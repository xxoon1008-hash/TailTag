import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../providers/tag_provider.dart';
import '../services/ble_service.dart';

class TagRegisterScreen extends StatefulWidget {
  const TagRegisterScreen({super.key});

  @override
  State<TagRegisterScreen> createState() => _TagRegisterScreenState();
}

class _TagRegisterScreenState extends State<TagRegisterScreen> {
  final BleService _bleService = BleService();
  final List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    final granted = await _bleService.requestBlePermissions();
    if (!mounted) return;

    setState(() {
      _permissionGranted = granted;
    });

    if (!granted) return;

    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    _bleService.scanForDevices().listen((results) {
      if (!mounted) return;
      setState(() {
        // 이름 있는 기기 우선, 중복 제거
        final seen = <String>{};
        _scanResults.clear();
        for (final r in results) {
          final id = r.device.remoteId.str;
          if (seen.add(id)) {
            _scanResults.add(r);
          }
        }
        _scanResults.sort((a, b) => b.rssi.compareTo(a.rssi));
      });
    });

    await Future.delayed(const Duration(seconds: 8));
    if (!mounted) return;
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _bleService.stopScan();
    super.dispose();
  }

  Future<void> _onDeviceSelected(ScanResult result) async {
    final deviceId = result.device.remoteId.str;

    final mac = deviceId.replaceAll(':', '').toUpperCase();
    final macSuffix = mac.length >= 4 ? mac.substring(mac.length - 4) : mac;
    final defaultName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'TAG-$macSuffix';

    final nameController = TextEditingController(text: defaultName);

    final confirmedName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('태그 이름 지정'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(hintText: '예: 지갑, 가방'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('등록'),
          ),
        ],
      ),
    );

    if (confirmedName == null || confirmedName.isEmpty) return;
    if (!mounted) return;

    try {
      await context.read<TagProvider>().registerTag(confirmedName, deviceId);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('태그 등록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: !_permissionGranted
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  '블루투스/위치 권한이 필요합니다.\n설정에서 권한을 허용해주세요.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                if (_isScanning) const LinearProgressIndicator(),
                Expanded(
                  child: _scanResults.isEmpty
                      ? Center(
                          child: Text(
                            _isScanning ? '주변 기기 검색 중...' : '검색된 기기가 없습니다.',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _scanResults.length,
                          itemBuilder: (context, index) {
                            final result = _scanResults[index];
                            final rawMac = result.device.remoteId.str.replaceAll(':', '').toUpperCase();
                            final suffix = rawMac.length >= 4 ? rawMac.substring(rawMac.length - 4) : rawMac;
                            final name = result.device.platformName.isNotEmpty
                                ? result.device.platformName
                                : 'TAG-$suffix';
                            final idLabel = result.device.remoteId.str;
                            return ListTile(
                              leading: const Icon(Icons.bluetooth_searching),
                              title: Text(name),
                              subtitle: Text(idLabel),
                              trailing: Text('${result.rssi} dBm'),
                              onTap: () => _onDeviceSelected(result),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}