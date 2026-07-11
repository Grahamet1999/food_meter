import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:food_meter/firebase_options.dart';
import 'package:food_meter/screens/pantry_list_screen.dart';
import 'package:food_meter/models/pantry_item.dart';
import 'package:food_meter/screens/item_detail_screen.dart';
import 'package:provider/provider.dart';
import 'providers/pantry_provider.dart';
import 'theme_examples.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen.dart';
import 'package:food_meter/screens/add_item_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/notification_service.dart';

/// Entry point of the application.
///
/// Wraps the app with [ChangeNotifierProvider] to provide [PantryProvider]
/// to the widget tree, enabling reactive state management for pantry items.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  // --- Firebase Messaging integration ---
  // Skipped on web: getToken() there needs a VAPID key (Cloud Messaging
  // > Web configuration in the Firebase console) plus a registered service
  // worker, neither of which is set up yet. Native platforms are unaffected.
  if (!kIsWeb) {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Save this device's FCM token so the daily expiration-reminder Cloud
    // Function can reach it.
    final fcmToken = await messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': fcmToken},
        SetOptions(merge: true),
      );
    }

    // Foreground FCM messages aren't shown by the OS automatically, so surface
    // them as a local notification.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService.showNotification(
          id: message.hashCode & 0x7FFFFFFF,
          title: notification.title ?? 'Food Meter',
          body: notification.body ?? '',
        );
      }
    });
  }
  // --- End Firebase Messaging integration ---

  runApp(
    ChangeNotifierProvider(
      create: (_) => PantryProvider(),
      child: const MainApp(),
    ),
  );
}

/// Main application widget with theme support.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Blues & Yellows ADA and color-blind friendly theme from theme_examples.dart
    return MaterialApp(
      theme: bluesYellowsLightTheme,
      darkTheme: bluesYellowsDarkTheme,
      themeMode: ThemeMode.system, // Uses system setting for light/dark mode
      routes: {
        '/addItem': (context) => const AddItemScreen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user != null) {
            return const PantryListScreen();
          } else {
            return const AuthScreen();
          }
        },
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/itemDetail' && settings.arguments is PantryItem) {
          return MaterialPageRoute(
            builder: (context) => ItemDetailScreen(item: settings.arguments as PantryItem),
          );
        }
        return null;
      },
    );
  }
}
