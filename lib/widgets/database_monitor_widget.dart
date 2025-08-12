import 'package:flutter/material.dart';
import '../services/database_query_service.dart';
import '../services/database_maintenance_service.dart';

/// Debug widget for monitoring database performance and statistics
class DatabaseMonitorWidget extends StatefulWidget {
  const DatabaseMonitorWidget({super.key});

  @override
  State<DatabaseMonitorWidget> createState() => _DatabaseMonitorWidgetState();
}

class _DatabaseMonitorWidgetState extends State<DatabaseMonitorWidget> {
  final DatabaseQueryService _queryService = DatabaseQueryService();
  final DatabaseMaintenanceService _maintenanceService =
      DatabaseMaintenanceService();

  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  MaintenanceReport? _lastMaintenanceReport;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await _queryService.getDatabaseStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading stats: $e')));
      }
    }
  }

  Future<void> _runMaintenance() async {
    setState(() => _isLoading = true);

    try {
      final report = await _maintenanceService.runMaintenance();
      setState(() {
        _lastMaintenanceReport = report;
        _isLoading = false;
      });
      await _loadStats(); // Refresh stats

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maintenance completed: ${report.summary}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Maintenance error: $e')));
      }
    }
  }

  void _clearQueryCache() {
    _queryService.clearAllCaches();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Query cache cleared')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Monitor'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadStats,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Stats',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildMaintenanceCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  if (_lastMaintenanceReport != null) ...[
                    const SizedBox(height: 16),
                    _buildMaintenanceReportCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    if (_stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No stats available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Database Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatRow('Mood Entries', _stats!['moodEntries']),
            _buildStatRow('Journal Entries', _stats!['journalEntries']),
            _buildStatRow('Audio Cache Entries', _stats!['audioCacheEntries']),
            _buildStatRow('Playlist Cache', _stats!['playlistCacheEntries']),
            _buildStatRow('HTTP Cache', _stats!['httpCacheEntries']),
            const Divider(),
            _buildStatRow(
              'Total Cache Size',
              _formatBytes(_stats!['totalCacheSize']),
            ),
            _buildStatRow('Query Cache Size', _stats!['queryCacheSize']),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Maintenance Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              'Automated Maintenance',
              _maintenanceService.isAutomatedMaintenanceActive
                  ? 'Active'
                  : 'Inactive',
            ),
            _buildStatRow(
              'Maintenance Running',
              _maintenanceService.isMaintenanceRunning ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _runMaintenance,
                  child: const Text('Run Maintenance'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearQueryCache,
                  child: const Text('Clear Cache'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceReportCard() {
    final report = _lastMaintenanceReport!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Maintenance Report',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (report.error != null)
              Text(
                'Error: ${report.error}',
                style: const TextStyle(color: Colors.red),
              )
            else ...[
              Text('Summary: ${report.summary}'),
              if (report.expiredCacheCleanup != null)
                Text('• ${report.expiredCacheCleanup}'),
              if (report.audioCacheOptimization != null)
                Text('• ${report.audioCacheOptimization}'),
              if (report.dataRetentionCleanup != null)
                Text('• ${report.dataRetentionCleanup}'),
              if (report.databaseOptimization != null)
                Text('• ${report.databaseOptimization}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
