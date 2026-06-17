import 'package:flutter/material.dart';
import 'constants.dart';
import 'screens/login_screen.dart';

void main() => runApp(const FreshKeeperApp());

class FreshKeeperApp extends StatelessWidget {
  const FreshKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshKeeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: kBg,
        primaryColor: kPrimary,
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: kPrimary,
          primaryContainer: kPrimaryLight,
          surface: kSurface,
          error: kError,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          foregroundColor: kTextMain,
          elevation: 0,
          centerTitle: false,
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      home: const LoginScreen(),
    );
  }
}