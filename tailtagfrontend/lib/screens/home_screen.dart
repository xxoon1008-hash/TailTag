import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tag_provider.dart';
import '../utils/ble_utils.dart';
import 'tag_register_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String deviceId) {
    setState(() {
      if (_selectedIds.contains(deviceId)) {
        _selectedIds.remove(deviceId);
      } else {
        _selectedIds.add(deviceId);
      }
    });
  }

  void _selectAll(List tags) {
    setState(() {
      if (_selectedIds.length == tags.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(tags.map((t) => t.deviceId as String));
      }
    });
  }

  Future<void> _deleteSelected(BuildContext context) async {
    final count = _selectedIds.length;
    final provider = context.read<TagProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('태그 삭제'),
        content: Text('선택한 태그 $count개를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    for (final id in List<String>.from(_selectedIds)) {
      await provider.removeTag(id);
    }
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = context.watch<TagProvider>();
    final tags = tagProvider.tags;
    final allSelected = tags.isNotEmpty && _selectedIds.length == tags.length;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              ),
              title: Text('${_selectedIds.length}개 선택됨'),
              actions: [
                TextButton(
                  onPressed: () => _selectAll(tags),
                  child: Text(allSelected ? '전체 해제' : '전체 선택'),
                ),
                if (_selectedIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSelected(context),
                  ),
              ],
            )
          : AppBar(
              title: const Text('내 태그'),
              actions: [
                if (tagProvider.isScanning)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (tags.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.checklist),
                    tooltip: '선택 삭제',
                    onPressed: _toggleSelectionMode,
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
                final isSelected = _selectedIds.contains(tag.deviceId);

                return _isSelectionMode
                    ? CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleSelect(tag.deviceId),
                        secondary: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.bluetooth,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tag.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: lastLocation != null
                            ? Row(
                                children: [
                                  Text(
                                    '마지막 감지: ${_formatDateTime(lastLocation.detectedAt)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  ),
                                  const SizedBox(width: 8),
                                  _DistanceChip(rssi: lastLocation.rssi),
                                ],
                              )
                            : Text(
                                '아직 감지된 기록이 없습니다',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                      )
                    : ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.bluetooth,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tag.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: lastLocation != null
                            ? Row(
                                children: [
                                  Text(
                                    '마지막 감지: ${_formatDateTime(lastLocation.detectedAt)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 8),
                                  _DistanceChip(rssi: lastLocation.rssi),
                                ],
                              )
                            : Text(
                                '아직 감지된 기록이 없습니다',
                                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () =>
                              _confirmDelete(context, tag.deviceId, tag.name),
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
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              context.read<TagProvider>().removeTag(deviceId);
              Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DistanceChip extends StatelessWidget {
  final int rssi;
  const _DistanceChip({required this.rssi});

  @override
  Widget build(BuildContext context) {
    final level = BleUtils.signalLevel(rssi);
    final colors = [Colors.red, Colors.orange, Colors.yellow[700]!, Colors.green];
    final color = colors[level];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        BleUtils.distanceLabel(rssi),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
