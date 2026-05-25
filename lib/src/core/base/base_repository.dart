/// Base Repository Interface
/// 
/// Defines the contract for data access in the SDK following
/// the Repository pattern from Domain-Driven Design.
/// 
/// ## Purpose
/// 
/// - Abstract data source implementation details
/// - Enable easy testing with mock implementations
/// - Support multiple data sources (API, cache, local DB)
/// - Provide consistent error handling across repositories
/// 
/// ## Why Repository Pattern?
/// 
/// The Repository pattern separates:
/// - WHAT data we need (domain layer)
/// - HOW we get it (data layer)
/// 
/// This allows:
/// - Swapping data sources without changing business logic
/// - Easier unit testing with mock repositories
/// - Consistent caching strategies
/// - Cleaner architecture boundaries
/// 
/// ## Data Flow
/// 
/// ```
/// Service → Repository Interface → Concrete Repository → Data Source
///                                                     ↓
///                                           (API / Cache / DB)
/// ```
/// 
/// ## Extension Points
/// 
/// - Implement for new entity types
/// - Add caching decorators
/// - Create composite repositories (API + Cache)
library;

import '../base/result.dart';
import '../../exceptions/dhis2_exception.dart';

/// Base interface for all repositories in the SDK.
/// 
/// [T] is the entity type this repository manages.
/// [ID] is the identifier type (usually String for DHIS2).
/// 
/// Example implementation:
/// ```dart
/// class DataElementRepository implements BaseRepository<DataElement, String> {
///   final HttpClient _client;
///   
///   @override
///   Future<Result<DataElement, Dhis2Exception>> getById(String id) async {
///     try {
///       final response = await _client.get('/dataElements/$id');
///       return Result.success(DataElement.fromJson(response.data));
///     } catch (e) {
///       return Result.failure(Dhis2Exception.fromError(e));
///     }
///   }
///   // ... other methods
/// }
/// ```
abstract interface class BaseRepository<T, ID> {
  /// Retrieves a single entity by its identifier.
  /// 
  /// Returns a [Result] containing either the entity or an error.
  Future<Result<T, Dhis2Exception>> getById(ID id);

  /// Retrieves all entities, optionally with pagination.
  /// 
  /// [page] - The page number (1-indexed).
  /// [pageSize] - Number of items per page.
  /// 
  /// Returns a [Result] containing either the list or an error.
  Future<Result<List<T>, Dhis2Exception>> getAll({
    int page = 1,
    int pageSize = 50,
  });

  /// Retrieves entities matching the given filter.
  /// 
  /// [filter] - A DHIS2 filter string (e.g., 'name:ilike:malaria').
  /// 
  /// Returns a [Result] containing either the filtered list or an error.
  Future<Result<List<T>, Dhis2Exception>> getByFilter(String filter);
}

/// Extended repository interface with additional query capabilities.
/// 
/// Use this for repositories that need more advanced querying.
abstract interface class ExtendedRepository<T, ID>
    implements BaseRepository<T, ID> {
  /// Retrieves entities by multiple IDs.
  /// 
  /// More efficient than multiple getById calls.
  Future<Result<List<T>, Dhis2Exception>> getByIds(List<ID> ids);

  /// Checks if an entity exists without fetching it.
  Future<Result<bool, Dhis2Exception>> exists(ID id);

  /// Counts entities matching optional filter.
  Future<Result<int, Dhis2Exception>> count({String? filter});

  /// Searches entities by name or code.
  Future<Result<List<T>, Dhis2Exception>> search(
    String query, {
    int maxResults = 50,
  });
}

/// Mixin for repositories that support caching.
/// 
/// Implement this to add caching behavior to a repository.
mixin CacheableRepository<T, ID> on BaseRepository<T, ID> {
  /// Retrieves from cache first, falls back to remote.
  Future<Result<T, Dhis2Exception>> getByIdCached(
    ID id, {
    bool forceRefresh = false,
  });

  /// Retrieves all from cache first, falls back to remote.
  Future<Result<List<T>, Dhis2Exception>> getAllCached({
    bool forceRefresh = false,
    int page = 1,
    int pageSize = 50,
  });

  /// Clears cached data for this repository.
  Future<void> clearCache();

  /// Checks if cached data is available and fresh.
  Future<bool> hasFreshCache();
}

/// Mixin for repositories that support offline operations.
mixin OfflineRepository<T, ID> on BaseRepository<T, ID> {
  /// Returns cached data when offline, error if no cache.
  Future<Result<T, Dhis2Exception>> getByIdOffline(ID id);

  /// Returns cached list when offline, error if no cache.
  Future<Result<List<T>, Dhis2Exception>> getAllOffline();

  /// Syncs local changes when connectivity is restored.
  /// 
  /// Note: This SDK is read-only, so sync only refreshes cache.
  Future<Result<void, Dhis2Exception>> syncWithRemote();
}
