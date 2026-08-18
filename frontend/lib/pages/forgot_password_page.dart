import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart'; // untuk pakai AppColors yang sama

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  int step = 1; // 1: email, 2: OTP, 3: password baru

  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  String email = "";
  String otp = "";

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ==========================
  // STEP 1 — Kirim OTP
  // ==========================
  Future<void> handleSendOtp() async {
    if (emailController.text.trim().isEmpty) {
      showError("Email wajib diisi");
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.sendOtp(emailController.text.trim());

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() {
        email = emailController.text.trim();
        step = 2;
      });
    } else {
      showError(result["message"] ?? "Gagal mengirim OTP");
    }
  }

  // ==========================
  // STEP 2 — Verifikasi OTP
  // ==========================
  Future<void> handleVerifyOtp() async {
    if (otpController.text.trim().length != 6) {
      showError("Masukkan kode OTP 6 digit");
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.verifyOtp(
      email,
      otpController.text.trim(),
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() {
        otp = otpController.text.trim();
        step = 3;
      });
    } else {
      showError(result["message"] ?? "OTP salah");
    }
  }

  // ==========================
  // STEP 3 — Reset Password
  // ==========================
  Future<void> handleResetPassword() async {
    if (passwordController.text.isEmpty) {
      showError("Password wajib diisi");
      return;
    }

    if (passwordController.text.length < 6) {
      showError("Password minimal 6 karakter");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showError("Konfirmasi password tidak sama");
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.resetPassword(
      email,
      otp,
      passwordController.text,
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password berhasil direset, silahkan login"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      showError(result["message"] ?? "Gagal reset password");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightest,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      if (step == 1) {
                        Navigator.pop(context);
                      } else {
                        setState(() => step--);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Icon(
                      Icons.lock_reset,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      step == 1
                          ? "Lupa Password"
                          : step == 2
                              ? "Verifikasi OTP"
                              : "Password Baru",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      step == 1
                          ? "Masukkan email akunmu"
                          : step == 2
                              ? "Kode OTP dikirim ke $email"
                              : "Buat password baru untuk akun\n$email",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// FORM
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// STEP INDICATOR
                    Row(
                      children: List.generate(3, (i) {
                        final active = i + 1 <= step;
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            height: 4,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.mediumDark
                                  : AppColors.light,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 28),

                    // ========== STEP 1: EMAIL ==========
                    if (step == 1) ...[
                      const Text(
                        "Email",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.darkest),
                        decoration: InputDecoration(
                          hintText: "contoh@email.com",
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.mediumDark,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.mediumDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.medium,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Kirim OTP",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],

                    // ========== STEP 2: OTP ==========
                    if (step == 2) ...[
                      const Text(
                        "Kode OTP",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                          color: AppColors.darkest,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "······",
                          hintStyle: const TextStyle(letterSpacing: 8),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.mediumDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Tidak menerima OTP? ",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkest,
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading ? null : handleSendOtp,
                            child: const Text(
                              "Kirim ulang",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mediumDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleVerifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.medium,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Verifikasi",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],

                    // ========== STEP 3: PASSWORD BARU ==========
                    if (step == 3) ...[
                      const Text(
                        "Password Baru",
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
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.mediumDark,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.medium,
                            ),
                            onPressed: () => setState(
                                () => obscurePassword = !obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.mediumDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Konfirmasi Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.darkest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        style: const TextStyle(color: AppColors.darkest),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: AppColors.mediumDark,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.medium,
                            ),
                            onPressed: () =>
                                setState(() => obscureConfirm = !obscureConfirm),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.mediumDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.medium,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Reset Password",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
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