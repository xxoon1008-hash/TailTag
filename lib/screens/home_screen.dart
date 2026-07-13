import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tag_provider.dart';
import 'tag_register_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 진입 시 주기적 스캔 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagProvider>().startPeriodicScan();
    });
  }

  @override
  void dispose() {
    context.read<TagProvider>().stopPeriodicScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final tags = tagProvider.tags;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TailTag'),
        actions: [
          if (tagProvider.isScanning)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: tags.isEmpty
          ? const Center(
        child: Text(
          '등록된 태그가 없습니다.\n오른쪽 아래 + 버튼으로 등록해보세요.',
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags[index];
          final lastLocation = tagProvider.lastLocationFor(tag.deviceId);

          return ListTile(
            leading: const Icon(Icons.bluetooth),
            title: Text(tag.name),
            subtitle: Text(
              lastLocation != null
                  ? '마지막 감지: ${_formatDateTime(lastLocation.detectedAt)}'
                  : '아직 감지된 기록이 없습니다',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, tag.deviceId, tag.name),
            ),
            onTap: lastLocation == null
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapScreen(tag: tag),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TagRegisterScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String deviceId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('"$name" 태그를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<TagProvider>().removeTag(deviceId);
              Navigator.pop(ctx);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}