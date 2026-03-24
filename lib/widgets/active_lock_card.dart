import 'package:flutter/material.dart';
import '../models/lock_status.dart';

class ActiveLockCard extends StatelessWidget {
  final LockStatus status;
  final VoidCallback? onUnlock;

  const ActiveLockCard({
    super.key,
    required this.status,
    this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = status.isHard ? Colors.red : Colors.amber;
    final appCount = status.lockedApps.length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 48, color: iconColor),
            const SizedBox(height: 12),
            Text(
              '$appCount app${appCount == 1 ? '' : 's'} locked',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Until ${status.endTimeFormatted}',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
            ),
            if (status.lockedAppNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                status.lockedAppNames.join(', '),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 16),
            if (status.isHard)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Hard Locked',
                    style: TextStyle(color: Colors.grey.shade500)),
              )
            else
              OutlinedButton.icon(
                onPressed: onUnlock,
                icon: const Icon(Icons.lock_open),
                label: const Text('Unlock'),
              ),
          ],
        ),
      ),
    );
  }
}
