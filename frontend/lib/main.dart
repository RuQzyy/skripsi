import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_success_page.dart';
import 'pages/profile_page.dart';
import 'pages/guru_dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
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
        "/onboarding":      (context) => const OnboardingPage(),
        "/login":           (context) => const LoginPage(),
        "/dashboard":       (context) => const DashboardPage(),
        "/guru-dashboard":  (context) => const GuruDashboardPage(),
        "/login-success":   (context) => const LoginSuccessPage(),
        "/profile":         (context) => const ProfilePage(),
      },
    );
  }
}