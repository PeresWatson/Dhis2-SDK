/// Status of data synchronization
enum SyncStatus {
  /// No sync in progress, no pending changes
  idle,
  
  /// Sync is currently in progress
  syncing,
  
  /// All data is synced with server
  synced,
  
  /// Some data synced, but operations pending
  partialSync,
  
  /// Sync failed
  error,
  
  /// Device is offline, sync pending
  offline,
}

/// Extension methods for SyncStatus
extension SyncStatusExtension on SyncStatus {
  /// Whether sync is complete
  bool get isComplete => this == SyncStatus.synced;
  
  /// Whether sync is in progress
  bool get isInProgress => this == SyncStatus.syncing;
  
  /// Whether there are pending changes
  bool get hasPendingChanges => 
      this == SyncStatus.partialSync || this == SyncStatus.offline;
  
  /// Whether sync failed
  bool get hasError => this == SyncStatus.error;
  
  /// Human-readable description
  String get description {
    switch (this) {
      case SyncStatus.idle:
        return 'Ready to sync';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        return 'All changes synced';
      case SyncStatus.partialSync:
        return 'Partially synced';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.offline:
        return 'Offline - changes pending';
    }
  }
  
  /// Icon name for UI representation
  String get iconName {
    switch (this) {
      case SyncStatus.idle:
        return 'cloud_queue';
      case SyncStatus.syncing:
        return 'cloud_sync';
      case SyncStatus.synced:
        return 'cloud_done';
      case SyncStatus.partialSync:
        return 'cloud_upload';
      case SyncStatus.error:
        return 'cloud_off';
      case SyncStatus.offline:
        return 'cloud_offline';
    }
  }
}

/// Detailed sync progress information
class SyncProgress {
  final SyncStatus status;
  final int totalItems;
  final int processedItems;
  final int failedItems;
  final String? currentOperation;
  final DateTime? lastSyncTime;
  final String? errorMessage;

  const SyncProgress({
    required this.status,
    this.totalItems = 0,
    this.processedItems = 0,
    this.failedItems = 0,
    this.currentOperation,
    this.lastSyncTime,
    this.errorMessage,
  });

  /// Progress percentage (0.0 to 1.0)
  double get progress {
    if (totalItems == 0) return 0.0;
    return processedItems / totalItems;
  }

  /// Progress percentage (0 to 100)
  int get progressPercent => (progress * 100).round();

  /// Whether sync is complete
  bool get isComplete => status == SyncStatus.synced;

  /// Create initial progress
  factory SyncProgress.initial() {
    return const SyncProgress(status: SyncStatus.idle);
  }

  /// Create syncing progress
  factory SyncProgress.syncing({
    required int total,
    required int processed,
    String? operation,
  }) {
    return SyncProgress(
      status: SyncStatus.syncing,
      totalItems: total,
      processedItems: processed,
      currentOperation: operation,
    );
  }

  /// Create completed progress
  factory SyncProgress.completed({
    int? totalItems,
    int? failedItems,
  }) {
    return SyncProgress(
      status: failedItems != null && failedItems > 0 
          ? SyncStatus.partialSync 
          : SyncStatus.synced,
      totalItems: totalItems ?? 0,
      processedItems: totalItems ?? 0,
      failedItems: failedItems ?? 0,
      lastSyncTime: DateTime.now(),
    );
  }

  /// Create error progress
  factory SyncProgress.error(String message) {
    return SyncProgress(
      status: SyncStatus.error,
      errorMessage: message,
    );
  }

  /// Copy with modifications
  SyncProgress copyWith({
    SyncStatus? status,
    int? totalItems,
    int? processedItems,
    int? failedItems,
    String? currentOperation,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return SyncProgress(
      status: status ?? this.status,
      totalItems: totalItems ?? this.totalItems,
      processedItems: processedItems ?? this.processedItems,
      failedItems: failedItems ?? this.failedItems,
      currentOperation: currentOperation ?? this.currentOperation,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'SyncProgress(status: ${status.name}, progress: $progressPercent%)';
  }
}
