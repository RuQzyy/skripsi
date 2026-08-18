import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'forgot_password_page.dart';

/// ===== PALET WARNA SIPRESMA 15 =====
class AppColors {
  static const Color lightest = Color(0xffF6FAFD);
  static const Color light = Color(0xffB3CFE5);
  static const Color medium = Color(0xff4A7FA7);
  static const Color mediumDark = Color(0xff1A3D63);
  static const Color darkest = Color(0xff0A1931);
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nisnNipController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  void login() async {
    if (nisnNipController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("NISN/NIP dan Password wajib diisi"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    var result = await AuthService.login(
      nisnNipController.text,
      passwordController.text,
    );

    setState(() {
      isLoading = false;
    });

    if (result["success"]) {
      Navigator.pushReplacementNamed(context, "/login-success");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Login gagal"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightest,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: 40,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.darkest,
                    AppColors.mediumDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(80),
                ),
              ),
              child: Column(
                children: [
                  /// BACK BUTTON
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, "/onboarding");
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// LOGO
                  Image.asset(
                    "assets/logo/SMA15.png",
                    height: 90,
                  ),

                  const SizedBox(height: 20),

                  /// TITLE
                  const Text(
                    "SELAMAT DATANG DI SIPRESMA 15 \nLOGIN UNTUK MELAKUKAN ABSENSI",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            /// FORM AREA
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// NISN/NIP
                    const Text(
                      "Nisn/Nip",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkest,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: nisnNipController,
                      style: const TextStyle(color: AppColors.darkest),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.light,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.light,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.mediumDark,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkest,
                      ),
                    ),

                    const SizedBox(height: 8),

                   TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      style: const TextStyle(color: AppColors.darkest),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.light,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.light,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.mediumDark,
                            width: 2,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.mediumDark,
                          ),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// LUPA PASSWORD
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Lupa Password?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkest,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    /// LOGIN BUTTON (beda warna dari header biar hidup)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.medium,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "LOGIN",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                 const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}