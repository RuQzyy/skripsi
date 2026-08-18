import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_success_page.dart';
import 'pages/profile_page.dart';
import 'pages/guru_dashboard_page.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Mulai dengarkan konektivitas & jalankan sync yang tertunda dari sesi
    // sebelumnya (kalau ada). Ini jalan sekali untuk seluruh app, tidak
    // perlu dipanggil lagi di halaman lain.
    SyncService.instance.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SyncService.instance.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Setiap kali app dibuka lagi dari background, coba sinkronkan antrian
    // -> ini jaring pengaman tambahan selain listener konektivitas,
    // untuk kasus di mana koneksi sebenarnya sudah kembali saat app masih
    // di background dan event-nya tidak sempat terpicu.
    if (state == AppLifecycleState.resumed) {
      SyncService.instance.syncNow();
    }
  }

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