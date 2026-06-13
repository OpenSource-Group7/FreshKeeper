import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // 로그인 스크린

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshKeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1B5E20), // 메인 컬러 (진한 초록)
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE6EEE9),
          foregroundColor: Color(0xFF1B5E20),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}