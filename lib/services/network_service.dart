// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'firebase/firebase_service.dart';

// class NetworkService {
//   static final NetworkService _instance = NetworkService._internal();
//   factory NetworkService() => _instance;
//   NetworkService._internal();
  
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription<ConnectivityResult>? _subscription;
//   bool _wasOffline = false;
  
//   // Initialize network monitoring
//   void initialize(BuildContext context) {
//     _subscription = _connectivity.onConnectivityChanged.listen((result) {
//       final isOnline = result != ConnectivityResult.none;
      
//       if (isOnline && _wasOffline) {
//         // Just came online
//         print('🌐 Internet connected - Syncing data...');
//         _syncPendingOperations(context);
//         _wasOffline = false;
//       } else if (!isOnline) {
//         // Went offline
//         print('📦 Offline mode - Data will be saved locally');
//         _wasOffline = true;
        
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.wifi_off, color: Colors.white),
//                 SizedBox(width: 8),
//                 Text('Offline - Changes will sync when online'),
//               ],
//             ),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     });
//   }
  
//   // Sync pending operations when online
//   Future<void> _syncPendingOperations(BuildContext context) async {
//     try {
//       await PendingSyncManager.syncAll();
      
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.cloud_done, color: Colors.white),
//                 SizedBox(width: 8),
//                 Text('All changes synced!'),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       print('Sync error: $e');
//     }
//   }
  
//   // Check if currently online
//   Future<bool> isOnline() async {
//     final result = await _connectivity.checkConnectivity();
//     return result != ConnectivityResult.none;
//   }
  
//   // Dispose
//   void dispose() {
//     _subscription?.cancel();
//   }
// }