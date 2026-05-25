import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';

import '../providers/sdk_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SystemInfo? _systemInfo;
  CacheStats? _cacheStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final sdk = context.read<SdkProvider>().sdk;
    if (sdk == null) return;

    try {
      // Load system info
      final systemResult = await sdk.metadata.getSystemInfo();
      if (systemResult.isSuccess) {
        _systemInfo = systemResult.data;
      }

      // Load cache stats
      _cacheStats = await sdk.getCacheStats();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<SdkProvider>();
    final user = provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => provider.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // User Card
                  if (user != null) _buildUserCard(theme, user),
                  const SizedBox(height: 16),

                  // System Info Card
                  if (_systemInfo != null) _buildSystemInfoCard(theme),
                  const SizedBox(height: 16),

                  // Cache Stats Card
                  if (_cacheStats != null) _buildCacheStatsCard(theme),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard(ThemeData theme, User user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName ?? 'User',
                    style: theme.textTheme.titleLarge,
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (user.organisationUnits != null && 
                      user.organisationUnits!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Chip(
                        label: Text(
                          '${user.organisationUnits!.length} Org Units',
                          style: theme.textTheme.labelSmall,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dns,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Information',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Version', _systemInfo?.version ?? 'N/A'),
            _buildInfoRow('System Name', _systemInfo?.systemName ?? 'N/A'),
            _buildInfoRow('Calendar', _systemInfo?.calendar ?? 'N/A'),
            _buildInfoRow('Date Format', _systemInfo?.dateFormat ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStatsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.storage,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cache Statistics',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Total Entries', '${_cacheStats!.totalEntries}'),
            _buildInfoRow('Fresh Entries', '${_cacheStats!.freshEntries}'),
            _buildInfoRow('Stale Entries', '${_cacheStats!.staleEntries}'),
            _buildInfoRow('Cache Size', _cacheStats!.formattedSize),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _cacheStats!.utilizationPercent / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 4),
            Text(
              '${_cacheStats!.utilizationPercent.toStringAsFixed(1)}% utilized',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Clear Cache'),
                  onPressed: () async {
                    final sdk = context.read<SdkProvider>().sdk;
                    await sdk?.clearCache();
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync Now'),
                  onPressed: () async {
                    final sdk = context.read<SdkProvider>().sdk;
                    final result = await sdk?.performSync();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result?.success == true
                                ? 'Sync completed'
                                : 'Sync failed: ${result?.message}',
                          ),
                        ),
                      );
                    }
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.wifi, size: 18),
                  label: Text(
                    context.read<SdkProvider>().sdk?.isOnline == true
                        ? 'Online'
                        : 'Offline',
                  ),
                  onPressed: null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
