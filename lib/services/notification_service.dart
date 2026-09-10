import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    // Request notification permissions (iOS)
    // Request notification permissions (iOS & Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('📱 Notification permission status: ${settings.authorizationStatus}');
    
    // For Android 13+, we might need to explicitly request POST_NOTIFICATIONS permission
    // This is handled by firebase_messaging plugin but good to verify
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notifications authorized');
    } else {
      print('❌ Notifications not authorized');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      // onDidReceiveLocalNotification: removed in newer versions
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
        // Handle notification tap
      },
    );

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Foreground message received: ${message.messageId}');
      
      if (message.notification != null) {
        showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification opened app: ${message.messageId}');
      // Navigate to appropriate screen based on message.data
    });

    // Get initial message if app was opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 App opened from terminated state via notification');
      // Handle the message
    }
  }

  // Get FCM token and save to Firestore
  Future<String?> getFCMToken(String userId) async {
    try {
      // Check if notifications are enabled
      final settings = await _firebaseMessaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('❌ Notifications not authorized: ${settings.authorizationStatus}');
        // Try requesting permission one more time
        final newSettings = await _firebaseMessaging.requestPermission();
        if (newSettings.authorizationStatus != AuthorizationStatus.authorized &&
            newSettings.authorizationStatus != AuthorizationStatus.provisional) {
           return null;
        }
      }

      // Try multiple times to get token (sometimes it fails on first app launch)
      String? token;
      int retries = 0;
      while (token == null && retries < 3) {
        try {
          token = await _firebaseMessaging.getToken();
          if (token == null) {
            print('⚠️ Token is null, retrying (${retries + 1}/3)...');
            await Future.delayed(const Duration(seconds: 2));
            retries++;
          }
        } catch (e) {
          print('⚠️ Error fetching token, retrying (${retries + 1}/3): $e');
          await Future.delayed(const Duration(seconds: 2));
          retries++;
        }
      }

      print('📱 FCM Token retrieved: ${token?.substring(0, 10)}...');
      
      if (token != null && userId.isNotEmpty) {
        // Save token to user document
        print('💾 Saving FCM token to Firestore for user $userId...');
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token saved to Firestore');
      } else {
        print('⚠️ Token is null or userId is empty after retries');
      }
      
      return token;
    } catch (e) {
      print('❌ Error getting/saving FCM token: $e');
      return null;
    }
  }

  // Listen to token refresh
  void listenToTokenRefresh(String userId) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('📱 FCM Token refreshed: $newToken');
      
      if (userId.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'foundation_channel',
      'Foundation Notifications',
      channelDescription: 'Notifications for Foundation app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> sendSMS(String phoneNumber, String message) async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      throw 'Could not launch SMS';
    }
  }
}
