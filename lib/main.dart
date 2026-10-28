import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'src/backend/auth_service.dart';
import 'src/backend/push_notification_service.dart';
import 'src/frontend/admin/admin_home_page.dart';
import 'src/frontend/login/login_page.dart';
import 'src/frontend/staff/pages/staff_home_page.dart';
import 'src/frontend/student/pages/student_home_page.dart';
import 'src/frontend/student/theme/student_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const MyApp());

  // Initialize push notification listeners asynchronously so runApp is never blocked.
  PushNotificationService().initialize();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  UserRole? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final authService = AuthService();
      final role = await authService.getCurrentRole();
      final user = await authService.getCurrentUser();

      if (user != null) {
        // Register device token in the background
        PushNotificationService().registerUserDevice(
          user.uid,
          role: user.role,
          username: user.username,
        );
      } else if (authService.firebaseUser != null) {
        // If an orphaned Firebase Auth session exists without a Firestore profile,
        // sign out cleanly so the login page can be presented.
        await authService.logout();
      }

      if (mounted) {
        setState(() {
          _role = user?.role ?? role;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading session: $e');
      if (mounted) {
        setState(() {
          _role = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: StudentTheme.lightTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Smart Meet',
      debugShowCheckedModeBanner: false,
      theme: StudentTheme.lightTheme(),
      home: _role == UserRole.student
          ? const StudentHomePage()
          : _role == UserRole.staff
              ? const StaffHomePage()
              : _role == UserRole.admin
                  ? const AdminHomePage()
              : const LoginPage(),
    );
  }
}
