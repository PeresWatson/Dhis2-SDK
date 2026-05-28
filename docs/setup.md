# DHIS2 SDK - Setup Guide

## Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- A DHIS2 instance

## Installation Steps

### 1. Add SDK to Your Project

```bash
# Clone the SDK repository
git clone https://github.com/PeresWatson/Dhis2-SDK.git
```

### 2. Add Dependencies

In your Flutter app's `pubspec.yaml`:

```yaml
dependencies:
  dhis2_sdk:
    path: ../path/to/dhis2_sdk
```

Run `flutter pub get`

### 3. Initialize SDK

In your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dhis2_sdk/dhis2_sdk.dart';
import 'package:dhis2_sdk/src/bindings/dhis2_bindings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = await openDatabase(
    'dhis2_sdk.db',
    version: 1,
    onCreate: (db, version) async {
      // Create tables
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          username TEXT UNIQUE NOT NULL,
          data TEXT NOT NULL
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tokens (
          token TEXT PRIMARY KEY,
          saved_at TEXT NOT NULL
        )
      ''');
    },
  );
  
  // Setup bindings
  Get.put(
    Dhis2Bindings(
      baseUrl: 'https://your-dhis2-instance.com',
      database: database,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DHIS2 App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
    );
  }
}
```

### 4. Create Login Screen

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dhis2_sdk/dhis2_sdk.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('DHIS2 Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              onChanged: authController.updateUsername,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => TextField(
              onChanged: authController.updatePassword,
              obscureText: !authController.isPasswordVisible.value,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    authController.isPasswordVisible.value
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: authController.togglePasswordVisibility,
                ),
              ),
            )),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
              onPressed: authController.isLoading.value
                  ? null
                  : () async {
                      final success = await authController.login();
                      if (success) {
                        Get.offNamed('/dashboard');
                      } else {
                        Get.snackbar(
                          'Login Error',
                          authController.errorMessage.value,
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      }
                    },
              child: authController.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('Login'),
            )),
          ],
        ),
      ),
    );
  }
}
```

### 5. Create Dashboard Screen

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dhis2_sdk/dhis2_sdk.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboardController = Get.find<DashboardController>();
    final connectivityController = Get.find<ConnectivityController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Get.find<AuthService>();
              await authService.logout();
              Get.offNamed('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Connectivity status
          Obx(() => Container(
            color: connectivityController.isOnline.value
                ? Colors.green
                : Colors.red,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              connectivityController.getStatusMessage(),
              style: const TextStyle(color: Colors.white),
            ),
          )),
          
          // Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: dashboardController.searchDashboards,
              decoration: InputDecoration(
                hintText: 'Search dashboards...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          
          // Dashboards list
          Expanded(
            child: Obx(() {
              if (dashboardController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (dashboardController.filteredDashboards.isEmpty) {
                return const Center(child: Text('No dashboards found'));
              }
              
              return ListView.builder(
                itemCount: dashboardController.filteredDashboards.length,
                itemBuilder: (context, index) {
                  final dashboard = dashboardController.filteredDashboards[index];
                  return ListTile(
                    title: Text(dashboard.name),
                    subtitle: Text(dashboard.description ?? ''),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () async {
                      await dashboardController.selectDashboard(dashboard.id);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await dashboardController.fetchDashboards();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
```

## Configuration

### DHIS2 Instance URL

Update the base URL in your initialization:

```dart
Dhis2Bindings(
  baseUrl: 'https://your-dhis2-instance.com',
  database: database,
)
```

### Logging

Enable/disable logging:

```dart
// Check logs in console
SdkLogger.debug('Debug message');
SdkLogger.info('Info message');
SdkLogger.warning('Warning message');
SdkLogger.error('Error message');
```

### Sync Configuration

Configure sync intervals:

```dart
// This will be implemented in SDK initialization
// Default: 1 hour
```

## Troubleshooting

### Database Lock Errors

Ensure database is properly initialized and closed in app lifecycle.

### Network Errors

Check your DHIS2 instance URL and network connectivity.

### Authentication Errors

Verify username and password are correct.

### State Management Issues

Ensure GetX bindings are properly initialized before using services.

## Next Steps

- Check [API Documentation](./api.md)
- Review [Integration Examples](./examples.md)
- Study [Architecture](./architecture.md)
- Run tests: `flutter test`
