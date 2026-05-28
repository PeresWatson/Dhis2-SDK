# DHIS2 SDK - API Documentation

## Services

### AuthService

Handles user authentication and session management.

```dart
final authService = Get.find<AuthService>();

// Properties
authService.currentUser;        // Current logged-in user
authService.authToken;          // Authentication token
authService.isAuthenticated;    // Authentication status
authService.isLoading;          // Loading state

// Methods
await authService.login('username', 'password');
await authService.logout();
String? token = authService.getToken();
bool isLoggedIn = authService.isLoggedIn;
UserModel? user = authService.user;
```

### DashboardService

Manages dashboard operations.

```dart
final dashboardService = Get.find<DashboardService>();

// Properties
dashboardService.dashboards;        // List of dashboards
dashboardService.selectedDashboard; // Currently selected dashboard
dashboardService.isLoading;         // Loading state

// Methods
await dashboardService.fetchDashboards();
await dashboardService.getDashboardById(id);
await dashboardService.createDashboard(dashboard);
await dashboardService.updateDashboard(dashboard);
await dashboardService.deleteDashboard(id);
```

### ConnectivityService

Monitors network connectivity.

```dart
final connectivityService = Get.find<ConnectivityService>();

// Properties
connectivityService.isOnline;        // Connection status
connectivityService.connectionType;  // Connection type (mobile/wifi/ethernet)

// Methods
bool hasConnection = connectivityService.hasConnection;
String type = connectivityService.connectionTypeString;
```

### SyncService

Handles data synchronization.

```dart
final syncService = Get.find<SyncService>();

// Properties
syncService.isSyncing;      // Sync in progress
syncService.syncQueueCount; // Pending sync tasks
syncService.lastSyncTime;   // Last sync timestamp
syncService.syncProgress;   // Sync progress (0-1)

// Methods
await syncService.startSync();
await syncService.queueSyncTask(resourceType, resourceId);
await syncService.clearQueue();
Map<String, dynamic> status = syncService.getSyncStatus();
```

### CacheService

Manages local caching.

```dart
final cacheService = Get.find<CacheService>();

// Properties
cacheService.cache;      // Cached data
cacheService.cacheSize;  // Number of cached items

// Methods
await cacheService.setCache(key, value);
dynamic value = cacheService.getCache(key);
await cacheService.removeCache(key);
await cacheService.clearCache();
bool exists = cacheService.hasCacheKey(key);
```

### PermissionService

Manages user permissions and roles.

```dart
final permissionService = Get.find<PermissionService>();

// Properties
permissionService.userRoles;       // User roles
permissionService.userPermissions; // User permissions

// Methods
bool hasRole = permissionService.hasRole(role);
bool hasPermission = permissionService.hasPermission(permission);
permissionService.addRole(role);
permissionService.removeRole(role);
permissionService.addPermission(permission);
permissionService.removePermission(permission);
permissionService.setUserRoles(roles);
permissionService.setUserPermissions(permissions);
permissionService.clearPermissions();
```

## Controllers

### AuthController

Manages authentication UI state.

```dart
final authController = Get.find<AuthController>();

// Properties
authController.username;        // Username input
authController.password;        // Password input
authController.isLoading;       // Loading state
authController.errorMessage;    // Error message
authController.isPasswordVisible; // Password visibility
authController.rememberMe;      // Remember me flag

// Methods
await authController.login();
authController.updateUsername(value);
authController.updatePassword(value);
authController.togglePasswordVisibility();
authController.toggleRememberMe();
authController.clearError();
authController.resetForm();
```

### DashboardController

Manages dashboard UI state.

```dart
final dashboardController = Get.find<DashboardController>();

// Properties
dashboardController.dashboards;         // All dashboards
dashboardController.filteredDashboards; // Filtered results
dashboardController.selectedDashboard;  // Selected dashboard
dashboardController.searchQuery;        // Search query
dashboardController.isLoading;          // Loading state

// Methods
await dashboardController.fetchDashboards();
await dashboardController.selectDashboard(id);
dashboardController.searchDashboards(query);
dashboardController.clearSearch();
int total = dashboardController.getTotalDashboardCount();
int filtered = dashboardController.getFilteredDashboardCount();
```

### ConnectivityController

Manages connectivity UI state.

```dart
final connectivityController = Get.find<ConnectivityController>();

// Properties
connectivityController.isOnline;       // Connection status
connectivityController.connectionType; // Connection type

// Methods
String message = connectivityController.getStatusMessage();
```

### SyncController

Manages synchronization UI state.

```dart
final syncController = Get.find<SyncController>();

// Properties
syncController.isSyncing;      // Sync in progress
syncController.queueCount;     // Pending tasks
syncController.lastSyncTime;   // Last sync time
syncController.syncProgress;   // Progress (0-1)

// Methods
await syncController.startSync();
Map<String, dynamic> status = syncController.getSyncStatus();
String percentage = syncController.getSyncProgressPercentage();
```

## Models

### UserModel

```dart
class UserModel {
  final String id;
  final String username;
  final String email;
  final String? firstName;
  final String? surname;
  final String? phone;
  final String? avatar;
  final List<String> roles;
  final bool active;
  final DateTime createdAt;
  final DateTime? lastLogin;
  
  String get fullName;
  bool hasRole(String role);
  Map<String, dynamic> toJson();
  factory UserModel.fromJson(Map<String, dynamic> json);
}
```

### DashboardModel

```dart
class DashboardModel {
  final String id;
  final String name;
  final String? description;
  final String? displayName;
  final int? itemCount;
  final bool? favorite;
  final bool? restricted;
  final DateTime? created;
  final DateTime? lastUpdated;
  final List<String> visualizations;
  final List<String> items;
  
  Map<String, dynamic> toJson();
  factory DashboardModel.fromJson(Map<String, dynamic> json);
}
```

### AuthResponseModel

```dart
class AuthResponseModel {
  final String token;
  final UserModel user;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? refreshToken;
  
  bool get isExpired;
  int get timeRemainingMinutes;
  Map<String, dynamic> toJson();
  factory AuthResponseModel.fromJson(Map<String, dynamic> json);
}
```

### SyncStatusModel

```dart
class SyncStatusModel {
  final String id;
  final String resourceType;
  final String resourceId;
  final SyncStatus status;
  final DateTime lastSyncTime;
  final int retryCount;
  final String? errorMessage;
  final String? errorCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  bool get isPending;
  bool get isFailed;
  bool get isSuccess;
  bool get isInProgress;
  Map<String, dynamic> toJson();
  factory SyncStatusModel.fromJson(Map<String, dynamic> json);
}

enum SyncStatus {
  pending,
  inProgress,
  success,
  failed,
  cancelled,
}
```

## Exceptions

### Custom Exceptions

```dart
// Base exception
abstract class Dhis2Exception implements Exception

// Specific exceptions
class NetworkException extends Dhis2Exception
class AuthenticationException extends Dhis2Exception
class AuthorizationException extends Dhis2Exception
class CacheException extends Dhis2Exception
class ValidationException extends Dhis2Exception
class ServerException extends Dhis2Exception
class SyncException extends Dhis2Exception
class DatabaseException extends Dhis2Exception

// Usage
try {
  await someAsyncOperation();
} on AuthenticationException catch (e) {
  print(e.message); // Get error message
  print(e.code);    // Get error code
} on NetworkException catch (e) {
  // Handle network error
}
```

## Utilities

### SdkLogger

```dart
SdkLogger.debug('Debug message');
SdkLogger.info('Info message');
SdkLogger.warning('Warning message');
SdkLogger.error('Error message', exception, stackTrace);
SdkLogger.fatal('Fatal message', exception, stackTrace);
```

### Validators

```dart
Validators.isValidEmail('email@example.com');
Validators.isValidUsername('username');
Validators.isValidPassword('Password123!');
Validators.isValidUrl('https://example.com');
Validators.isValidPhoneNumber('+1234567890');
Validators.isNotEmpty('value');
int strength = Validators.getPasswordStrength('password');
```

## Best Practices

1. **Always use dependency injection**
   ```dart
   final service = Get.find<ServiceType>();
   ```

2. **Handle reactive updates**
   ```dart
   Obx(() => Text(authService.currentUser.value?.username ?? ''))
   ```

3. **Catch specific exceptions**
   ```dart
   try {
     // operation
   } on AuthenticationException {
     // handle auth error
   } on NetworkException {
     // handle network error
   }
   ```

4. **Check connectivity before operations**
   ```dart
   if (connectivityService.hasConnection) {
     await dashboardService.fetchDashboards();
   }
   ```

5. **Monitor sync progress**
   ```dart
   Obx(() => LinearProgressIndicator(
     value: syncController.syncProgress.value,
   ))
   ```
