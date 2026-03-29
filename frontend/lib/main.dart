import 'package:flutter/material.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_success_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      initialRoute: "/onboarding",

      routes: {
        "/onboarding": (context) => const OnboardingPage(),
        "/login": (context) => const LoginPage(),
        "/dashboard": (context) => const DashboardPage(),
        "/login-success": (context) => const LoginSuccessPage(),
        "/profile": (context) => const ProfilePage(),
      },
    );
  }
}