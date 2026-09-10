import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import '../models/tag.dart';
import '../providers/tag_provider.dart';
import '../utils/ble_utils.dart';

class TagFinderScreen extends StatefulWidget {
  final Tag tag;
  const TagFinderScreen({super.key, required this.tag});

  @override
  State<TagFinderScreen> createState() => _TagFinderScreenState();
}

class _TagFinderScreenState extends State<TagFinderScreen>
    with TickerProviderStateMixin {
  static const int _historySize = 6;

  final List<int> _rssiHistory = [];
  int? _smoothedRssi;
  DateTime? _lastSeen;

  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _refreshTimer;
  late TagProvider _tagProvider;

  // 3개의 ripple 링
  late final List<AnimationController> _rippleControllers;
  late final List<Animation<double>> _rippleAnimations;

  @override
  void initState() {
    super.initState();
    // dispose()에서 context를 사용할 수 없으므로 미리 저장
    _tagProvider = context.read<TagProvider>();
    _initRipple();
    _startScan();
    // UI를 1초마다 갱신해 "신호 없음" 상태를 즉시 반영
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // 백그라운드 주기 스캔 일시 정지
    _tagProvider.stopPeriodicScan();
  }

  void _initRipple() {
    _rippleControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
    });
    _rippleAnimations = _rippleControllers.map((c) {
      return Tween<double>(begin: 0.0, end: 1.0)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeOut));
    }).toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 650), () {
        if (mounted) _rippleControllers[i].repeat();
      });
    }
  }

  Future<void> _startScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.remoteId.str == widget.tag.deviceId) {
          _onRssi(r.rssi);
        }
      }
    });
    await FlutterBluePlus.startScan(continuousUpdates: true);
  }

  void _onRssi(int rssi) {
    _rssiHistory.add(rssi);
    if (_rssiHistory.length > _historySize) _rssiHistory.removeAt(0);
    final avg = _rssiHistory.reduce((a, b) => a + b) ~/ _rssiHistory.length;

    // 거리에 따라 ripple 속도 조절
    final level = BleUtils.signalLevel(avg);
    final ms = [3200, 2400, 1600, 1000][level];
    for (final c in _rippleControllers) {
      if (c.duration?.inMilliseconds != ms) {
        c.duration = Duration(milliseconds: ms);
      }
    }

    if (mounted) {
      setState(() {
        _smoothedRssi = avg;
        _lastSeen = DateTime.now();
      });
    }
  }

  bool get _signalLost =>
      _lastSeen != null &&
      DateTime.now().difference(_lastSeen!) > const Duration(seconds: 5);

  bool get _hasSignal => _smoothedRssi != null && !_signalLost;

  @override
  void dispose() {
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    _refreshTimer?.cancel();
    for (final c in _rippleControllers) {
      c.dispose();
    }
    _tagProvider.startPeriodicScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rssi = _smoothedRssi;
    final level = _hasSignal ? BleUtils.signalLevel(rssi!) : -1;
    final List<Color> levelColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow[700]!,
      Colors.green,
    ];
    final color = _hasSignal ? levelColors[level] : Colors.grey;

    final String statusText;
    final String subText;
    if (!_hasSignal && _lastSeen == null) {
      statusText = '신호 검색 중';
      subText = '주변에서 "${widget.tag.name}"을(를) 찾고 있어요';
    } else if (_signalLost) {
      statusText = '신호 없음';
      subText = '태그가 범위를 벗어났거나 꺼져 있어요';
    } else {
      statusText = BleUtils.distanceLabel(rssi!);
      subText = '마지막 수신: $rssi dBm';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.tag.name),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ripple + 중심 아이콘
            SizedBox(
              width: 300,
              height: 300,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_hasSignal)
                    ...List.generate(3, (i) {
                      return AnimatedBuilder(
                        animation: _rippleAnimations[i],
                        builder: (_, child) {
                          final v = _rippleAnimations[i].value;
                          final maxR = _rippleRadius(rssi!);
                          return Container(
                            width: maxR * 2 * v,
                            height: maxR * 2 * v,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withValues(alpha: (1 - v) * 0.55),
                                width: 2.5,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  // 중심 원
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2.5),
                    ),
                    child: Icon(
                      _hasSignal
                          ? Icons.bluetooth_searching
                          : Icons.bluetooth_disabled,
                      color: color,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 거리 텍스트
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              child: Text(statusText),
            ),

            const SizedBox(height: 8),

            Text(
              subText,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),

            const SizedBox(height: 32),

            // 신호 막대
            _SignalBars(level: level),

            const SizedBox(height: 8),
            Text(
              _hasSignal ? _signalLabel(level) : '',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 신호 강도에 따라 ripple 최대 반지름 결정 (가까울수록 작게)
  double _rippleRadius(int rssi) {
    final dist = BleUtils.rssiToDistance(rssi);
    return (55 + min(dist * 5, 85)).toDouble();
  }

  String _signalLabel(int level) {
    return ['매우 약함', '약함', '보통', '강함'][level];
  }
}

class _SignalBars extends StatelessWidget {
  final int level; // -1: no signal, 0~3
  const _SignalBars({required this.level});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow[700]!,
      Colors.green,
    ];
    final color = level >= 0 ? colors[level] : Colors.grey[300]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = level >= 0 && i <= level;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 14,
          height: 10 + (i * 10).toDouble(),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? color : Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
