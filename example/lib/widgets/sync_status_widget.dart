import 'package:flutter/material.dart';
import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';

/// A widget that displays the current sync status and provides
/// manual sync controls.
class SyncStatusWidget extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onSyncPressed;
  final bool compact;

  const SyncStatusWidget({
    super.key,
    required this.status,
    this.onSyncPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildCompact(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIcon(),
        const SizedBox(width: 8),
        if (status.state == SyncState.syncing)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (onSyncPressed != null)
          IconButton(
            icon: const Icon(Icons.sync, size: 20),
            onPressed: status.state == SyncState.syncing ? null : onSyncPressed,
            tooltip: 'Sync now',
          ),
      ],
    );
  }

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatusIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (status.state == SyncState.syncing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (onSyncPressed != null)
                ElevatedButton.icon(
                  onPressed: onSyncPressed,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sync'),
                ),
            ],
          ),
          if (status.state == SyncState.syncing && status.progress != null) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: status.progress! / 100,
              backgroundColor: _getStatusColor().withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(_getStatusColor()),
            ),
            const SizedBox(height: 8),
            Text(
              '${status.progress!.toStringAsFixed(0)}% complete',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (status.lastSyncTime != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  'Last sync: ${_formatLastSync(status.lastSyncTime!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
          if (status.error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status.error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color = _getStatusColor();

    switch (status.state) {
      case SyncState.idle:
        icon = Icons.cloud_done;
        break;
      case SyncState.syncing:
        icon = Icons.sync;
        break;
      case SyncState.completed:
        icon = Icons.check_circle;
        break;
      case SyncState.failed:
        icon = Icons.error;
        break;
      case SyncState.offline:
        icon = Icons.cloud_off;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: compact ? 16 : 24),
    );
  }

  Color _getStatusColor() {
    switch (status.state) {
      case SyncState.idle:
        return Colors.grey;
      case SyncState.syncing:
        return Colors.blue;
      case SyncState.completed:
        return Colors.green;
      case SyncState.failed:
        return Colors.red;
      case SyncState.offline:
        return Colors.orange;
    }
  }

  String _getStatusTitle() {
    switch (status.state) {
      case SyncState.idle:
        return 'Ready to sync';
      case SyncState.syncing:
        return 'Syncing...';
      case SyncState.completed:
        return 'Sync complete';
      case SyncState.failed:
        return 'Sync failed';
      case SyncState.offline:
        return 'Offline';
    }
  }

  String _getStatusDescription() {
    switch (status.state) {
      case SyncState.idle:
        return 'Data is up to date';
      case SyncState.syncing:
        return status.currentOperation ?? 'Synchronizing data...';
      case SyncState.completed:
        return 'All data synchronized successfully';
      case SyncState.failed:
        return 'An error occurred during sync';
      case SyncState.offline:
        return 'No internet connection';
    }
  }

  String _formatLastSync(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

/// A widget that displays connectivity status
class ConnectivityIndicator extends StatelessWidget {
  final bool isConnected;
  final bool showLabel;

  const ConnectivityIndicator({
    super.key,
    required this.isConnected,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isConnected ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        ],
      ],
    );
  }
}
