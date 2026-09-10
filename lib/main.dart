import 'package:flutter/material.dart';

import 'src/frontend/student/pages/student_home_page.dart';
import 'src/frontend/student/theme/student_theme.dart';
import 'src/frontend/student/services/theme_service.dart';

final themeService = ThemeService();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Smart Meet',
          debugShowCheckedModeBanner: false,
          theme: StudentTheme.lightTheme(),
          darkTheme: StudentTheme.darkTheme(),
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const StudentHomePage(),
        );
      },
    );
  }
}
