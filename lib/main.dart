import 'package:flutter/material.dart';

import 'src/frontend/student/pages/student_home_page.dart';
import 'src/frontend/student/theme/student_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Meet',
      debugShowCheckedModeBanner: false,
      theme: StudentTheme.theme(),
      home: const StudentHomePage(),
    );
  }
}