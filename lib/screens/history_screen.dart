import 'package:flutter/material.dart';
import '../models/lock_history_entry.dart';
import '../services/lock_channel.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _lockChannel = LockChannel();
  List<LockHistoryEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _lockChannel.getHistory();
      if (!mounted) return;
      setState(() => _entries = entries.reversed.toList());
    } catch (_) {
      if (mounted) setState(() => _entries = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
      ),
      body: _entries == null
          ? const Center(child: CircularProgressIndicator())
          : _entries!.isEmpty
              ? Center(
                  child: Text('No lock history yet',
                      style: TextStyle(
                          fontSize: 16, color: Colors.grey.shade500)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _entries!.length,
                  itemBuilder: (context, index) {
                    final e = _entries![index];
                    return _buildCard(e);
                  },
                ),
    );
  }

  Widget _buildCard(LockHistoryEntry e) {
    final iconColor = e.wasHard ? Colors.red : Colors.amber;
    final appsText = e.appNames.isNotEmpty
        ? e.appNames.join(', ')
        : 'Unknown apps';

    final start = e.startTime;
    final end = e.endTime;
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayName = dayNames[start.weekday - 1];
    final monthName = monthNames[start.month - 1];
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = e.endEpoch > 0
        ? '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}'
        : '...';
    final dateStr =
        '$dayName ${start.day} $monthName \u00b7 $startStr \u2013 $endStr';
    final durationStr = e.formattedDuration;

    Widget? trailing;
    if (e.wasInterrupted) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Interrupted',
            style: TextStyle(color: Colors.red, fontSize: 11)),
      );
    } else if (e.wasHard) {
      trailing = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Hard',
            style: TextStyle(color: Color(0xFF9F67FF), fontSize: 11)),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.lock, color: iconColor),
        title: Text(appsText, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$dateStr  \u00b7  $durationStr',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: trailing,
      ),
    );
  }
}
