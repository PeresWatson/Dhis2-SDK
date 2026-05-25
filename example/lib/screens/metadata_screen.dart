import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dhis2_flutter_sdk/dhis2_flutter_sdk.dart';

import '../providers/sdk_provider.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metadata'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Org Units', icon: Icon(Icons.account_tree)),
            Tab(text: 'Data Elements', icon: Icon(Icons.data_object)),
            Tab(text: 'Indicators', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OrganisationUnitsTab(),
          _DataElementsTab(),
          _IndicatorsTab(),
        ],
      ),
    );
  }
}

class _OrganisationUnitsTab extends StatefulWidget {
  const _OrganisationUnitsTab();

  @override
  State<_OrganisationUnitsTab> createState() => _OrganisationUnitsTabState();
}

class _OrganisationUnitsTabState extends State<_OrganisationUnitsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  List<OrganisationUnit> _orgUnits = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final sdk = context.read<SdkProvider>().sdk;
    if (sdk == null) return;

    try {
      final result = await sdk.metadata.getOrganisationUnits(
        level: 1,
        pageSize: 50,
      );

      if (result.isSuccess) {
        _orgUnits = result.data ?? [];
      } else {
        _error = result.error?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError(theme);
    }

    if (_orgUnits.isEmpty) {
      return _buildEmpty(theme, 'No organisation units found');
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _orgUnits.length,
        itemBuilder: (context, index) {
          final ou = _orgUnits[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${ou.level ?? 1}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            title: Text(ou.name),
            subtitle: ou.code != null ? Text(ou.code!) : null,
            trailing: ou.children != null && ou.children!.isNotEmpty
                ? Chip(
                    label: Text('${ou.children!.length}'),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            onTap: () => _showOrgUnitDetails(ou),
          );
        },
      ),
    );
  }

  void _showOrgUnitDetails(OrganisationUnit ou) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ou.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('ID', ou.id),
              if (ou.code != null) _buildDetailRow('Code', ou.code!),
              if (ou.shortName != null) _buildDetailRow('Short Name', ou.shortName!),
              if (ou.level != null) _buildDetailRow('Level', ou.level.toString()),
              if (ou.path != null) _buildDetailRow('Path', ou.path!),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 48, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }
}

class _DataElementsTab extends StatefulWidget {
  const _DataElementsTab();

  @override
  State<_DataElementsTab> createState() => _DataElementsTabState();
}

class _DataElementsTabState extends State<_DataElementsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  List<DataElement> _dataElements = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final sdk = context.read<SdkProvider>().sdk;
    if (sdk == null) return;

    try {
      final result = await sdk.metadata.getDataElements(
        domainType: 'AGGREGATE',
        pageSize: 50,
      );

      if (result.isSuccess) {
        _dataElements = result.data ?? [];
      } else {
        _error = result.error?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_dataElements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('No data elements found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _dataElements.length,
        itemBuilder: (context, index) {
          final de = _dataElements[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Icon(
                Icons.data_object,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            title: Text(de.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              de.valueType ?? 'Unknown type',
              style: theme.textTheme.bodySmall,
            ),
            trailing: de.aggregationType != null
                ? Chip(
                    label: Text(
                      de.aggregationType!.substring(0, 3),
                      style: theme.textTheme.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _IndicatorsTab extends StatefulWidget {
  const _IndicatorsTab();

  @override
  State<_IndicatorsTab> createState() => _IndicatorsTabState();
}

class _IndicatorsTabState extends State<_IndicatorsTab>
    with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  String? _error;
  List<Indicator> _indicators = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final sdk = context.read<SdkProvider>().sdk;
    if (sdk == null) return;

    try {
      final result = await sdk.metadata.getIndicators(pageSize: 50);

      if (result.isSuccess) {
        _indicators = result.data ?? [];
      } else {
        _error = result.error?.toString();
      }
    } catch (e) {
      _error = e.toString();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_indicators.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('No indicators found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _indicators.length,
        itemBuilder: (context, index) {
          final indicator = _indicators[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: Icon(
                Icons.trending_up,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            title: Text(indicator.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: indicator.shortName != null
                ? Text(indicator.shortName!, style: theme.textTheme.bodySmall)
                : null,
            trailing: indicator.annualized == true
                ? const Chip(
                    label: Text('Annual'),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          );
        },
      ),
    );
  }
}
