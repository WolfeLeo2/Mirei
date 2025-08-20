import 'dart:async';
import 'package:realm/realm.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../utils/journal_grouping_service.dart';

/// Service for handling paginated loading of journal entries for performance optimization
class JournalPaginationService {
  static const int _defaultPageSize = 50;
  static const int _maxCachedPages = 5;
  
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();
  final Map<int, List<JournalEntryRealm>> _pageCache = {};
  final StreamController<Map<String, List<JournalEntryRealm>>> _dataController = 
      StreamController<Map<String, List<JournalEntryRealm>>>.broadcast();
  
  int _currentPage = 0;
  bool _hasMoreData = true;
  bool _isLoading = false;
  List<JournalEntryRealm> _allLoadedEntries = [];
  
  /// Stream of grouped journal entries by month
  Stream<Map<String, List<JournalEntryRealm>>> get groupedEntriesStream => 
      _dataController.stream;
  
  /// Load initial page of journal entries
  Future<Map<String, List<JournalEntryRealm>>> loadInitialPage({
    int pageSize = _defaultPageSize,
  }) async {
    _resetPagination();
    return await loadNextPage(pageSize: pageSize);
  }
  
  /// Load next page of journal entries
  Future<Map<String, List<JournalEntryRealm>>> loadNextPage({
    int pageSize = _defaultPageSize,
  }) async {
    if (_isLoading || !_hasMoreData) {
      return _getGroupedEntries();
    }
    
    _isLoading = true;
    
    try {
      // Check cache first
      if (_pageCache.containsKey(_currentPage)) {
        final cachedEntries = _pageCache[_currentPage]!;
        _allLoadedEntries.addAll(cachedEntries);
      } else {
        // Load from database
        final entries = await _loadEntriesFromDatabase(
          offset: _currentPage * pageSize,
          limit: pageSize,
        );
        
        if (entries.length < pageSize) {
          _hasMoreData = false;
        }
        
        // Cache the page
        _pageCache[_currentPage] = entries;
        _allLoadedEntries.addAll(entries);
        
        // Limit cache size to prevent memory issues
        if (_pageCache.length > _maxCachedPages) {
          final oldestPage = _pageCache.keys.reduce((a, b) => a < b ? a : b);
          _pageCache.remove(oldestPage);
        }
      }
      
      _currentPage++;
      final groupedEntries = _getGroupedEntries();
      _dataController.add(groupedEntries);
      
      return groupedEntries;
    } catch (e) {
      _hasMoreData = false;
      return _getGroupedEntries();
    } finally {
      _isLoading = false;
    }
  }
  
  /// Refresh all data (clear cache and reload)
  Future<Map<String, List<JournalEntryRealm>>> refresh({
    int pageSize = _defaultPageSize,
  }) async {
    _resetPagination();
    _pageCache.clear();
    return await loadNextPage(pageSize: pageSize);
  }
  
  /// Load entries from database with offset and limit
  Future<List<JournalEntryRealm>> _loadEntriesFromDatabase({
    required int offset,
    required int limit,
  }) async {
    return await _dbHelper.getJournalEntries(
      offset: offset,
      limit: limit,
      orderBy: 'createdAt DESC',
    );
  }
  
  /// Group loaded entries by month
  Map<String, List<JournalEntryRealm>> _getGroupedEntries() {
    return JournalGroupingService.groupJournalsByMonth(_allLoadedEntries);
  }
  
  /// Reset pagination state
  void _resetPagination() {
    _currentPage = 0;
    _hasMoreData = true;
    _isLoading = false;
    _allLoadedEntries.clear();
  }
  
  /// Get current loading state
  bool get isLoading => _isLoading;
  
  /// Check if more data is available
  bool get hasMoreData => _hasMoreData;
  
  /// Get total loaded entries count
  int get loadedEntriesCount => _allLoadedEntries.length;
  
  /// Preload next page in background for better UX
  Future<void> preloadNextPage({int pageSize = _defaultPageSize}) async {
    if (_hasMoreData && !_isLoading) {
      // Load in background without updating UI
      unawaited(loadNextPage(pageSize: pageSize));
    }
  }
  
  /// Dispose resources
  void dispose() {
    _dataController.close();
    _pageCache.clear();
  }
}

/// Extension to RealmDatabaseHelper for pagination support
extension PaginationExtension on RealmDatabaseHelper {
  /// Get journal entries with pagination support
  Future<List<JournalEntryRealm>> getJournalEntries({
    int offset = 0,
    int limit = 50,
    String orderBy = 'createdAt DESC',
  }) async {
    final realmDb = await realm;
    
    // Parse orderBy to determine sort field and direction
    final parts = orderBy.split(' ');
    final field = parts.first;
    final ascending = parts.length > 1 && parts[1].toUpperCase() == 'ASC';
    
    // Create query with sorting
    RealmResults<JournalEntryRealm> results;
    
    switch (field) {
      case 'createdAt':
        results = ascending 
            ? realmDb.all<JournalEntryRealm>().query('TRUEPREDICATE SORT(createdAt ASC)')
            : realmDb.all<JournalEntryRealm>().query('TRUEPREDICATE SORT(createdAt DESC)');
        break;
      case 'title':
        results = ascending
            ? realmDb.all<JournalEntryRealm>().query('TRUEPREDICATE SORT(title ASC)')
            : realmDb.all<JournalEntryRealm>().query('TRUEPREDICATE SORT(title DESC)');
        break;
      default:
        // Default to createdAt DESC
        results = realmDb.all<JournalEntryRealm>().query('TRUEPREDICATE SORT(createdAt DESC)');
    }
    
    // Convert to list and apply pagination
    final allResults = results.toList();
    final endIndex = (offset + limit).clamp(0, allResults.length);
    
    if (offset >= allResults.length) {
      return [];
    }
    
    return allResults.sublist(offset, endIndex);
  }
} 