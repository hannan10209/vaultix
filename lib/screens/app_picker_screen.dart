import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/installed_app_info.dart';
import '../services/lock_channel.dart';

class AppPickerScreen extends StatefulWidget {
  const AppPickerScreen({super.key});

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  final _lockChannel = LockChannel();
  List<InstalledAppInfo> _allApps = [];
  bool _loading = true;
  String _searchQuery = '';
  final Set<String> _selected = {};

  List<InstalledAppInfo> get _filteredApps {
    if (_searchQuery.isEmpty) return _allApps;
    final query = _searchQuery.toLowerCase();
    return _allApps
        .where((app) => app.appName.toLowerCase().contains(query))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final apps = await _lockChannel.getInstalledApps();
      apps.sort(
          (a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _allApps = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Apps to Block'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search apps...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      final isSelected = _selected.contains(app.packageName);
                      return ListTile(
                        leading: _buildIcon(app.iconBase64),
                        title: Text(app.appName),
                        subtitle: Text(app.packageName,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selected.add(app.packageName);
                              } else {
                                _selected.remove(app.packageName);
                              }
                            });
                          },
                        ),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.remove(app.packageName);
                            } else {
                              _selected.add(app.packageName);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Colors.grey.shade800),
          ),
        ),
        child: Row(
          children: [
            Text('${_selected.length} app${_selected.length == 1 ? '' : 's'} selected',
                style: const TextStyle(fontSize: 16)),
            const Spacer(),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(_selected),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String base64Str) {
    try {
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, width: 40, height: 40, fit: BoxFit.contain);
    } catch (_) {
      return const Icon(Icons.android, size: 40);
    }
  }
}
