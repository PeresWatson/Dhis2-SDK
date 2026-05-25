/// User Model
/// 
/// Represents an authenticated DHIS2 user with their
/// profile information and permissions.
/// 
/// ## Purpose
/// 
/// - Store user identity information
/// - Track user permissions/authorities
/// - Provide access to user's organization units
/// - Enable role-based UI decisions
/// 
/// ## Data Source
/// 
/// Populated from the /api/me endpoint response.
library;

import 'package:equatable/equatable.dart';

/// Represents an authenticated DHIS2 user.
/// 
/// Example:
/// ```dart
/// final user = User.fromJson(response['user']);
/// print('Logged in as: ${user.displayName}');
/// print('Has analytics access: ${user.hasAuthority('M_dhis-web-data-visualizer')}');
/// ```
class User extends Equatable {
  /// Unique identifier.
  final String id;

  /// Username for login.
  final String username;

  /// First name.
  final String? firstName;

  /// Surname/last name.
  final String? surname;

  /// Display name (usually firstName + surname).
  final String displayName;

  /// Email address.
  final String? email;

  /// Phone number.
  final String? phoneNumber;

  /// User interface language code.
  final String? uiLocale;

  /// Database language code.
  final String? dbLocale;

  /// List of authority strings the user has.
  final List<String> authorities;

  /// IDs of organization units the user can access for data entry.
  final List<String> organisationUnitIds;

  /// IDs of organization units the user can view data from.
  final List<String> dataViewOrganisationUnitIds;

  /// User role IDs.
  final List<String> userRoleIds;

  /// User group IDs.
  final List<String> userGroupIds;

  /// When the user account was created.
  final DateTime? created;

  /// When the user last logged in.
  final DateTime? lastLogin;

  /// Creates a new User instance.
  const User({
    required this.id,
    required this.username,
    required this.displayName,
    this.firstName,
    this.surname,
    this.email,
    this.phoneNumber,
    this.uiLocale,
    this.dbLocale,
    this.authorities = const [],
    this.organisationUnitIds = const [],
    this.dataViewOrganisationUnitIds = const [],
    this.userRoleIds = const [],
    this.userGroupIds = const [],
    this.created,
    this.lastLogin,
  });

  /// Creates a User from JSON response.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String? ?? json['userCredentials']?['username'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      firstName: json['firstName'] as String?,
      surname: json['surname'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      uiLocale: json['settings']?['keyUiLocale'] as String?,
      dbLocale: json['settings']?['keyDbLocale'] as String?,
      authorities: _parseStringList(json['authorities']),
      organisationUnitIds: _parseIdList(json['organisationUnits']),
      dataViewOrganisationUnitIds: _parseIdList(json['dataViewOrganisationUnits']),
      userRoleIds: _parseIdList(json['userRoles']),
      userGroupIds: _parseIdList(json['userGroups']),
      created: _parseDateTime(json['created']),
      lastLogin: _parseDateTime(json['lastLogin']),
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'displayName': displayName,
      'firstName': firstName,
      'surname': surname,
      'email': email,
      'phoneNumber': phoneNumber,
      'authorities': authorities,
      'organisationUnits': organisationUnitIds.map((id) => {'id': id}).toList(),
      'dataViewOrganisationUnits': dataViewOrganisationUnitIds.map((id) => {'id': id}).toList(),
      'userRoles': userRoleIds.map((id) => {'id': id}).toList(),
      'userGroups': userGroupIds.map((id) => {'id': id}).toList(),
    };
  }

  /// Checks if user has a specific authority.
  /// 
  /// Example:
  /// ```dart
  /// if (user.hasAuthority('M_dhis-web-dashboard')) {
  ///   // Show dashboard menu
  /// }
  /// ```
  bool hasAuthority(String authority) {
    return authorities.contains(authority) || authorities.contains('ALL');
  }

  /// Checks if user has any of the given authorities.
  bool hasAnyAuthority(List<String> requiredAuthorities) {
    if (authorities.contains('ALL')) return true;
    return requiredAuthorities.any(authorities.contains);
  }

  /// Checks if user has all of the given authorities.
  bool hasAllAuthorities(List<String> requiredAuthorities) {
    if (authorities.contains('ALL')) return true;
    return requiredAuthorities.every(authorities.contains);
  }

  /// Whether this user is a superuser (has ALL authority).
  bool get isSuperUser => authorities.contains('ALL');

  /// Gets the user's initials for avatar display.
  String get initials {
    if (firstName != null && surname != null) {
      return '${firstName![0]}${surname![0]}'.toUpperCase();
    }
    if (displayName.isNotEmpty) {
      final parts = displayName.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName[0].toUpperCase();
    }
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, username];

  @override
  String toString() => 'User(id: $id, username: $username)';
}

// Helper functions for parsing JSON
List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return [];
}

List<String> _parseIdList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) {
      if (e is Map) return e['id'] as String? ?? '';
      return e.toString();
    }).where((id) => id.isNotEmpty).toList();
  }
  return [];
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
