import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = false;
  
  // ✅ Public getter for isOnline
  bool get isOnline => _isOnline;

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    debugPrint('🌐 Initializing ConnectivityService...');
    
    try {
      // Check initial connectivity
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      
      // Listen to connectivity changes
      _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
        _updateConnectionStatus(results);
      });
      
      debugPrint('✅ ConnectivityService initialized - Status: ${_isOnline ? "Online" : "Offline"}');
    } catch (e) {
      debugPrint('❌ Error initializing connectivity: $e');
      _isOnline = false;
    }
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    
    // Update online status - online if any connection exists
    _isOnline = results.isNotEmpty && 
                !results.every((result) => result == ConnectivityResult.none);
    
    // Notify listeners if status changed
    if (wasOnline != _isOnline) {
      debugPrint('📡 Connectivity changed: ${_isOnline ? "Online ✅" : "Offline ❌"}');
      notifyListeners();
    }
  }

  // ==================== METHODS ====================

  /// Check if device is currently connected to internet
  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _isOnline = results.isNotEmpty && 
                  !results.every((result) => result == ConnectivityResult.none);
      notifyListeners();
      return _isOnline;
    } catch (e) {
      debugPrint('❌ Error checking connectivity: $e');
      _isOnline = false;
      notifyListeners();
      return false;
    }
  }

  /// Get current connection types (can have multiple connections)
  Future<List<ConnectivityResult>> getConnectionTypes() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('❌ Error getting connection types: $e');
      return [ConnectivityResult.none];
    }
  }

  /// Check if connected via WiFi
  Future<bool> isWifiConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }

  /// Check if connected via Mobile data
  Future<bool> isMobileConnected() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.mobile);
    } catch (e) {
      return false;
    }
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.isNotEmpty && 
             !results.every((result) => result == ConnectivityResult.none);
    });
  }
}