import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';

class LoginSuccessPage extends StatefulWidget {
  const LoginSuccessPage({super.key});

  @override
  State<LoginSuccessPage> createState() => _LoginSuccessPageState();
}

class _LoginSuccessPageState extends State<LoginSuccessPage> {

 @override
  void initState() {
    super.initState();
    _redirectAfterLogin();
  }

  Future<void> _redirectAfterLogin() async {
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final user = await AuthService.getUser();
    final role = (user?["role"] ?? "siswa").toString().toLowerCase();

    if (!mounted) return;

    if (role == "guru") {
      Navigator.pushReplacementNamed(context, "/guru-dashboard");
    } else {
      Navigator.pushReplacementNamed(context, "/dashboard");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "assets/images/bg.jpg", 
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                SizedBox(
                  height: 150,
                  child: Lottie.asset(
                    "assets/lottie/animasi.json", 
                    repeat: true,
                  ),
                ),

                const SizedBox(height: 20),

                /// TEXT
                const Text(
                  "AbsenKITA",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}