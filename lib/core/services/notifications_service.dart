import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static String? targetId;

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Notifications for coffee status',
      importance: Importance.max,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: 'order_updates',
      ),
      iosConfiguration: IosConfiguration(),
    );
  }

  static void startMonitoringOrder(String orderId) {
    targetId = orderId;
    final service = FlutterBackgroundService();

    // Slight delay to ensure the background isolate is listening
    Future.delayed(const Duration(milliseconds: 500), () {
      service.invoke("setOrderId", {"id": orderId});
    });
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 1. RE-INITIALIZE SUPABASE FOR THE BACKGROUND ISOLATE
  // This is critical because the background isolate has no access to main's memory
  await Supabase.initialize(
    url: 'https://wunkujstxrjifcqefiju.supabase.co', // REPLACE WITH YOUR URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1bmt1anN0eHJqaWZjcWVmaWp1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYzNzk0MTYsImV4cCI6MjA4MTk1NTQxNn0.OrmnN5LmxPR6x0nMARQAKlqjMxqzBHVP9HliYxWvBZo', // REPLACE WITH YOUR ANON KEY
  );

  String? activeOrderId;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 2. Listen for the order ID from the UI
  service.on('setOrderId').listen((event) {
    if (event != null && event['id'] != null) {
      activeOrderId = event['id'].toString();
    }
  });

  final supabase = Supabase.instance.client;

  // 3. Listen to the Realtime Stream
  supabase.from('orders').stream(primaryKey: ['id']).listen((
    List<Map<String, dynamic>> data,
  ) {
    if (activeOrderId == null) return;

    for (var o in data) {
      if (o['id'].toString() == activeOrderId) {
        String status = (o['status'] ?? '').toString().toLowerCase();

        // Notify for any change beyond the initial state
        if (status == 'paid' ||
            status == 'busy' ||
            status == 'ready' ||
            status == 'collected') {
          _showPopup(
            flutterLocalNotificationsPlugin,
            "Order Status: ${status.toUpperCase()}",
            "Your coffee is now $status!",
          );
        }
      }
    }
  });
}

void _showPopup(
  FlutterLocalNotificationsPlugin plugin,
  String title,
  String body,
) {
  // Use a fixed notification ID (1) so each new notification replaces the previous one
  plugin.show(
    1,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'order_updates',
        'Order Updates',
        icon: '@mipmap/ic_launcher',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: false,
      ),
    ),
  );
}
