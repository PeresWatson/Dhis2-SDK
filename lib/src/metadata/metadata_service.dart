import '../core/base/result.dart';
import '../network/http_client.dart';
import '../cache/cache_manager.dart';
import '../logging/sdk_logger.dart';

/// Service for fetching and managing DHIS2 metadata.
/// 
/// Handles organisation units, data elements, indicators, datasets,
/// and other metadata used across the DHIS2 system.
class MetadataService {
  final Dhis2HttpClient _httpClient;
  final CacheManager _cacheManager;
  final SdkLogger _logger;

  MetadataService({
    required Dhis2HttpClient httpClient,
    required CacheManager cacheManager,
    SdkLogger? logger,
  })  : _httpClient = httpClient,
        _cacheManager = cacheManager,
        _logger = logger ?? SdkLogger();

  // ============================================================
  // Organisation Units
  // ============================================================

  /// Get organisation units with optional filters
  Future<Result<List<OrganisationUnit>>> getOrganisationUnits({
    List<String>? ids,
    String? parentId,
    int? level,
    bool includeChildren = false,
    bool includeAncestors = false,
    List<String>? fields,
    int? pageSize,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'paging': pageSize != null,
        if (pageSize != null) 'pageSize': pageSize,
        if (page != null) 'page': page,
        if (ids != null && ids.isNotEmpty) 'filter': 'id:in:[${ids.join(",")}]',
        if (parentId != null) 'filter': 'parent.id:eq:$parentId',
        if (level != null) 'level': level,
        'fields': fields?.join(',') ?? 
            'id,name,shortName,code,level,path,parent[id,name],children[id,name]',
      };

      final cacheKey = 'metadata:organisationUnits:${queryParams.hashCode}';
      
      // Try cache first
      final cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        return Result.success(_parseOrganisationUnits(cached));
      }

      final response = await _httpClient.get(
        '/api/organisationUnits',
        queryParameters: queryParams,
      );

      if (response != null) {
        await _cacheManager.set(
          cacheKey, 
          response,
          duration: const Duration(hours: 24),
        );
        return Result.success(_parseOrganisationUnits(response));
      }

      return Result.failure(Exception('Failed to fetch organisation units'));
    } catch (e) {
      _logger.error('Failed to get organisation units', tag: 'MetadataService', error: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Get organisation unit hierarchy tree
  Future<Result<OrganisationUnit>> getOrganisationUnitTree(
    String rootId, {
    int? maxLevel,
  }) async {
    try {
      final fields = 'id,name,shortName,code,level,path,children[id,name,shortName,level,children::isNotEmpty]';
      
      if (maxLevel != null && maxLevel > 1) {
        // Build nested children fields up to maxLevel
        var childFields = 'id,name,shortName,level';
        for (int i = 1; i < maxLevel; i++) {
          childFields = 'id,name,shortName,level,children[$childFields]';
        }
      }

      final response = await _httpClient.get(
        '/api/organisationUnits/$rootId',
        queryParameters: {'fields': fields},
      );

      if (response != null) {
        return Result.success(OrganisationUnit.fromJson(response));
      }

      return Result.failure(Exception('Organisation unit not found'));
    } catch (e) {
      _logger.error('Failed to get organisation unit tree', tag: 'MetadataService', error: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================
  // Data Elements
  // ============================================================

  /// Get data elements with optional filters
  Future<Result<List<DataElement>>> getDataElements({
    List<String>? ids,
    String? domainType,
    String? valueType,
    String? dataSetId,
    List<String>? fields,
    int? pageSize,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'paging': pageSize != null,
        if (pageSize != null) 'pageSize': pageSize,
        if (page != null) 'page': page,
        if (ids != null && ids.isNotEmpty) 'filter': 'id:in:[${ids.join(",")}]',
        if (domainType != null) 'filter': 'domainType:eq:$domainType',
        if (valueType != null) 'filter': 'valueType:eq:$valueType',
        if (dataSetId != null) 'filter': 'dataSetElements.dataSet.id:eq:$dataSetId',
        'fields': fields?.join(',') ?? 
            'id,name,shortName,code,description,valueType,domainType,aggregationType,categoryCombo[id,name]',
      };

      final cacheKey = 'metadata:dataElements:${queryParams.hashCode}';
      
      final cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        return Result.success(_parseDataElements(cached));
      }

      final response = await _httpClient.get(
        '/api/dataElements',
        queryParameters: queryParams,
      );

      if (response != null) {
        await _cacheManager.set(
          cacheKey, 
          response,
          duration: const Duration(hours: 24),
        );
        return Result.success(_parseDataElements(response));
      }

      return Result.failure(Exception('Failed to fetch data elements'));
    } catch (e) {
      _logger.error('Failed to get data elements', tag: 'MetadataService', error: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================
  // Indicators
  // ============================================================

  /// Get indicators with optional filters
  Future<Result<List<Indicator>>> getIndicators({
    List<String>? ids,
    String? indicatorGroupId,
    List<String>? fields,
    int? pageSize,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'paging': pageSize != null,
        if (pageSize != null) 'pageSize': pageSize,
        if (page != null) 'page': page,
        if (ids != null && ids.isNotEmpty) 'filter': 'id:in:[${ids.join(",")}]',
        if (indicatorGroupId != null) 'filter': 'indicatorGroups.id:eq:$indicatorGroupId',
        'fields': fields?.join(',') ?? 
            'id,name,shortName,code,description,indicatorType[id,name,factor],numerator,denominator,annualized',
      };

      final cacheKey = 'metadata:indicators:${queryParams.hashCode}';
      
      final cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        return Result.success(_parseIndicators(cached));
      }

      final response = await _httpClient.get(
        '/api/indicators',
        queryParameters: queryParams,
      );

      if (response != null) {
        await _cacheManager.set(
          cacheKey, 
          response,
          duration: const Duration(hours: 24),
        );
        return Result.success(_parseIndicators(response));
      }

      return Result.failure(Exception('Failed to fetch indicators'));
    } catch (e) {
      _logger.error('Failed to get indicators', tag: 'MetadataService', error: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================
  // Data Sets
  // ============================================================

  /// Get data sets with optional filters
  Future<Result<List<DataSet>>> getDataSets({
    List<String>? ids,
    String? organisationUnitId,
    List<String>? fields,
    int? pageSize,
    int? page,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'paging': pageSize != null,
        if (pageSize != null) 'pageSize': pageSize,
        if (page != null) 'page': page,
        if (ids != null && ids.isNotEmpty) 'filter': 'id:in:[${ids.join(",")}]',
        if (organisationUnitId != null) 'filter': 'organisationUnits.id:eq:$organisationUnitId',
        'fields': fields?.join(',') ?? 
            'id,name,shortName,code,description,periodType,dataSetElements[dataElement[id,name]],organisationUnits[id,name]',
      };

      final cacheKey = 'metadata:dataSets:${queryParams.hashCode}';
      
      final cached = await _cacheManager.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        return Result.success(_parseDataSets(cached));
      }

      final response = await _httpClient.get(
        '/api/dataSets',
        queryParameters: queryParams,
      );

      if (response != null) {
        await _cacheManager.set(
          cacheKey, 
          response,
          duration: const Duration(hours: 24),
        );
        return Result.success(_parseDataSets(response));
      }

      return Result.failure(Exception('Failed to fetch data sets'));
    } catch (e) {
      _logger.error('Failed to get data sets', tag: 'MetadataService', error: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================
  // Category Options
  // ============================================================

  /// Get category option combos
  Future<Result<List<CategoryOptionCombo>>> getCategoryOptionCombos({
    String? categoryComboId,
    List<String>? fields,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (categoryComboId != null) 'filter': 'categoryCombo.id:eq:$categoryComboId',
        'fields': fields?.join(',') ?? 'id,name,shortName,categoryOptions[id,name]',
      };

      final response = await _httpClient.get(
        '/api/categoryOptionCombos',
        queryParameters: queryParams,
      );

      if (response != null) {
        return Result.success(_parseCategoryOptionCombos(response));
      }

      return Result.failure(Exception('Failed to fetch category option combos'));
    } catch (e) {
      _logger.error('Failed to get category option combos', tag: 'MetadataService', error: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================
  // System Info
  // ============================================================

  /// Get DHIS2 system information
  Future<Result<SystemInfo>> getSystemInfo() async {
    try {
      final response = await _httpClient.get('/api/system/info');

      if (response != null) {
        return Result.success(SystemInfo.fromJson(response));
      }

      return Result.failure(Exception('Failed to fetch system info'));
    } catch (e) {
      _logger.error('Failed to get system info', tag: 'MetadataService', error: e);
      return Result.failure(e is Exception ? e : Exception(e.toString()));
    }
  }

  // ============================================================
  // Helper Methods
  // ============================================================

  List<OrganisationUnit> _parseOrganisationUnits(Map<String, dynamic> response) {
    final units = response['organisationUnits'] as List<dynamic>? ?? [];
    return units.map((u) => OrganisationUnit.fromJson(u)).toList();
  }

  List<DataElement> _parseDataElements(Map<String, dynamic> response) {
    final elements = response['dataElements'] as List<dynamic>? ?? [];
    return elements.map((e) => DataElement.fromJson(e)).toList();
  }

  List<Indicator> _parseIndicators(Map<String, dynamic> response) {
    final indicators = response['indicators'] as List<dynamic>? ?? [];
    return indicators.map((i) => Indicator.fromJson(i)).toList();
  }

  List<DataSet> _parseDataSets(Map<String, dynamic> response) {
    final dataSets = response['dataSets'] as List<dynamic>? ?? [];
    return dataSets.map((d) => DataSet.fromJson(d)).toList();
  }

  List<CategoryOptionCombo> _parseCategoryOptionCombos(Map<String, dynamic> response) {
    final combos = response['categoryOptionCombos'] as List<dynamic>? ?? [];
    return combos.map((c) => CategoryOptionCombo.fromJson(c)).toList();
  }
}

// ============================================================
// Metadata Models
// ============================================================

/// DHIS2 Organisation Unit
class OrganisationUnit {
  final String id;
  final String name;
  final String? shortName;
  final String? code;
  final int? level;
  final String? path;
  final OrganisationUnit? parent;
  final List<OrganisationUnit>? children;

  const OrganisationUnit({
    required this.id,
    required this.name,
    this.shortName,
    this.code,
    this.level,
    this.path,
    this.parent,
    this.children,
  });

  factory OrganisationUnit.fromJson(Map<String, dynamic> json) {
    return OrganisationUnit(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'],
      code: json['code'],
      level: json['level'],
      path: json['path'],
      parent: json['parent'] != null 
          ? OrganisationUnit.fromJson(json['parent']) 
          : null,
      children: (json['children'] as List<dynamic>?)
          ?.map((c) => OrganisationUnit.fromJson(c))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (shortName != null) 'shortName': shortName,
      if (code != null) 'code': code,
      if (level != null) 'level': level,
      if (path != null) 'path': path,
      if (parent != null) 'parent': parent!.toJson(),
      if (children != null) 'children': children!.map((c) => c.toJson()).toList(),
    };
  }
}

/// DHIS2 Data Element
class DataElement {
  final String id;
  final String name;
  final String? shortName;
  final String? code;
  final String? description;
  final String? valueType;
  final String? domainType;
  final String? aggregationType;
  final Map<String, dynamic>? categoryCombo;

  const DataElement({
    required this.id,
    required this.name,
    this.shortName,
    this.code,
    this.description,
    this.valueType,
    this.domainType,
    this.aggregationType,
    this.categoryCombo,
  });

  factory DataElement.fromJson(Map<String, dynamic> json) {
    return DataElement(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'],
      code: json['code'],
      description: json['description'],
      valueType: json['valueType'],
      domainType: json['domainType'],
      aggregationType: json['aggregationType'],
      categoryCombo: json['categoryCombo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (shortName != null) 'shortName': shortName,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (valueType != null) 'valueType': valueType,
      if (domainType != null) 'domainType': domainType,
      if (aggregationType != null) 'aggregationType': aggregationType,
      if (categoryCombo != null) 'categoryCombo': categoryCombo,
    };
  }
}

/// DHIS2 Indicator
class Indicator {
  final String id;
  final String name;
  final String? shortName;
  final String? code;
  final String? description;
  final Map<String, dynamic>? indicatorType;
  final String? numerator;
  final String? denominator;
  final bool? annualized;

  const Indicator({
    required this.id,
    required this.name,
    this.shortName,
    this.code,
    this.description,
    this.indicatorType,
    this.numerator,
    this.denominator,
    this.annualized,
  });

  factory Indicator.fromJson(Map<String, dynamic> json) {
    return Indicator(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'],
      code: json['code'],
      description: json['description'],
      indicatorType: json['indicatorType'],
      numerator: json['numerator'],
      denominator: json['denominator'],
      annualized: json['annualized'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (shortName != null) 'shortName': shortName,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (indicatorType != null) 'indicatorType': indicatorType,
      if (numerator != null) 'numerator': numerator,
      if (denominator != null) 'denominator': denominator,
      if (annualized != null) 'annualized': annualized,
    };
  }
}

/// DHIS2 Data Set
class DataSet {
  final String id;
  final String name;
  final String? shortName;
  final String? code;
  final String? description;
  final String? periodType;
  final List<Map<String, dynamic>>? dataSetElements;
  final List<Map<String, dynamic>>? organisationUnits;

  const DataSet({
    required this.id,
    required this.name,
    this.shortName,
    this.code,
    this.description,
    this.periodType,
    this.dataSetElements,
    this.organisationUnits,
  });

  factory DataSet.fromJson(Map<String, dynamic> json) {
    return DataSet(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'],
      code: json['code'],
      description: json['description'],
      periodType: json['periodType'],
      dataSetElements: (json['dataSetElements'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      organisationUnits: (json['organisationUnits'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (shortName != null) 'shortName': shortName,
      if (code != null) 'code': code,
      if (description != null) 'description': description,
      if (periodType != null) 'periodType': periodType,
      if (dataSetElements != null) 'dataSetElements': dataSetElements,
      if (organisationUnits != null) 'organisationUnits': organisationUnits,
    };
  }
}

/// DHIS2 Category Option Combo
class CategoryOptionCombo {
  final String id;
  final String name;
  final String? shortName;
  final List<Map<String, dynamic>>? categoryOptions;

  const CategoryOptionCombo({
    required this.id,
    required this.name,
    this.shortName,
    this.categoryOptions,
  });

  factory CategoryOptionCombo.fromJson(Map<String, dynamic> json) {
    return CategoryOptionCombo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shortName: json['shortName'],
      categoryOptions: (json['categoryOptions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (shortName != null) 'shortName': shortName,
      if (categoryOptions != null) 'categoryOptions': categoryOptions,
    };
  }
}

/// DHIS2 System Information
class SystemInfo {
  final String? version;
  final String? revision;
  final String? buildTime;
  final String? serverDate;
  final String? contextPath;
  final String? systemId;
  final String? systemName;
  final String? instanceBaseUrl;
  final String? calendar;
  final String? dateFormat;

  const SystemInfo({
    this.version,
    this.revision,
    this.buildTime,
    this.serverDate,
    this.contextPath,
    this.systemId,
    this.systemName,
    this.instanceBaseUrl,
    this.calendar,
    this.dateFormat,
  });

  factory SystemInfo.fromJson(Map<String, dynamic> json) {
    return SystemInfo(
      version: json['version'],
      revision: json['revision'],
      buildTime: json['buildTime'],
      serverDate: json['serverDate'],
      contextPath: json['contextPath'],
      systemId: json['systemId'],
      systemName: json['systemName'],
      instanceBaseUrl: json['instanceBaseUrl'],
      calendar: json['calendar'],
      dateFormat: json['dateFormat'],
    );
  }

  /// Get major version number (e.g., "2.40" from "2.40.1")
  String? get majorVersion {
    if (version == null) return null;
    final parts = version!.split('.');
    if (parts.length >= 2) {
      return '${parts[0]}.${parts[1]}';
    }
    return version;
  }

  /// Check if version is at least the specified version
  bool isAtLeast(String minVersion) {
    if (version == null) return false;
    
    final currentParts = version!.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final minParts = minVersion.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    
    for (int i = 0; i < minParts.length; i++) {
      if (i >= currentParts.length) return false;
      if (currentParts[i] > minParts[i]) return true;
      if (currentParts[i] < minParts[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      if (version != null) 'version': version,
      if (revision != null) 'revision': revision,
      if (buildTime != null) 'buildTime': buildTime,
      if (serverDate != null) 'serverDate': serverDate,
      if (contextPath != null) 'contextPath': contextPath,
      if (systemId != null) 'systemId': systemId,
      if (systemName != null) 'systemName': systemName,
      if (instanceBaseUrl != null) 'instanceBaseUrl': instanceBaseUrl,
      if (calendar != null) 'calendar': calendar,
      if (dateFormat != null) 'dateFormat': dateFormat,
    };
  }
}
